import Darwin
import Dispatch
import Foundation
import SwiftLLDB

final class Adapter: DebugAdapterServerRequestHandler {
    static let shared = Adapter()
    
    let connection = DebugAdapterConnection(transport: DebugAdapterFileHandleTransport())
    
    private(set) var isRunning = false
    
    func resume() {
        guard !isRunning else {
            return
        }
        isRunning = true
        
        signal(SIGINT) { _ in Adapter.shared.cancel() }
        signal(SIGTERM) { _ in Adapter.shared.cancel() }
        
        var configuration = DebugAdapterConnection.Configuration()
        configuration.messageQueue = .main
        configuration.invalidationHandler = { [weak self] error in
            self?.cancel(error: error)
        }
        configuration.requestHandler = self
        
        connection.setConfiguration(configuration)
        connection.start()
        
        dispatchMain()
    }
    
    func cancel(error: Error? = nil) {
        guard isRunning else {
            return
        }
        isRunning = false
        
        connection.stop()
        
        exit(error != nil ? EXIT_FAILURE : EXIT_SUCCESS)
    }
    
    enum AdapterError: LocalizedError {
        case notDebugging
        case invalidated
        case invalidParameter(String)
        
        var errorDescription: String? {
            switch self {
            case .notDebugging:
                return "No debuggee is running."
            case .invalidated:
                return "The session has ended."
            case let .invalidParameter(reason):
                return "Invalid parameter: \(reason)"
            }
        }
    }
    
    private func output(_ message: @autoclosure () -> String, category: DebugAdapter.OutputEvent.Category = .console) {
        connection.send(DebugAdapter.OutputEvent(output: message(), category: category))
    }
    
    // MARK: - Lifecycle
    
    private var debugger: Debugger?
    private var eventsTask: Task<(), Never>?
    
    private struct ClientOptions: Sendable {
        var clientID: String?
        var clientName: String?
        var adapterID: String?
        var linesStartAt1 = true
        var columnsStartAt1 = true
    }
    private var clientOptions = ClientOptions()
    
    private enum ExceptionFilter: String, Sendable, Hashable, CaseIterable {
        case cxxCatch = "cpp_catch"
        case cxxThrow = "cpp_throw"
        case objcCatch = "objc_catch"
        case objcThrow = "objc_throw"
        case swiftCatch = "swift_catch"
        case swiftThrow = "swift_throw"
        
        var name: String {
            switch self {
            case .cxxCatch:
                return "C++ Catch"
            case .cxxThrow:
                return "C++ Throw"
            case .objcCatch:
                return "Objective-C Catch"
            case .objcThrow:
                return "Objective-C Throw"
            case .swiftCatch:
                return "Swift Catch"
            case .swiftThrow:
                return "Swift Throw"
            }
        }
        
        var language: Language {
            switch self {
            case .cxxCatch, .cxxThrow:
                return .cxx
            case .objcCatch, .objcThrow:
                return .objC
            case .swiftCatch, .swiftThrow:
                return .swift
            }
        }
        
        var isCatch: Bool { rawValue.hasSuffix("_catch") }
        
        var isThrow: Bool { rawValue.hasSuffix("_throw") }
        
        var filter: DebugAdapter.ExceptionBreakpointFilter {
            var filter = DebugAdapter.ExceptionBreakpointFilter(filter: rawValue, label: name)
            filter.supportsCondition = true
            return filter
        }
    }
    
    func initialize(_ request: DebugAdapter.InitializeRequest, replyHandler: @escaping (Result<DebugAdapter.InitializeRequest.Result?, Error>) -> Void) {
        // Initialize LLDB
        do {
            try Debugger.initialize()
        }
        catch {
            replyHandler(.failure(error))
            return
        }
        
        // Debugger
        self.debugger = Debugger()
        
        // Client options
        var options = ClientOptions()
        options.clientID = request.clientID
        options.clientName = request.clientName
        options.adapterID = request.adapterID
        options.linesStartAt1 = request.linesStartAt1 ?? true
        options.columnsStartAt1 = request.columnsStartAt1 ?? true
        clientOptions = options
        
        // Event listener
        eventsTask = Task {
            await listenForEvents()
        }
        
        // Capabilities
        var capabilities = DebugAdapter.Capabilities()
        
        capabilities.supportsConfigurationDoneRequest = true
        
        capabilities.supportsFunctionBreakpoints = true
        capabilities.supportsConditionalBreakpoints = true
        
        capabilities.exceptionBreakpointFilters = ExceptionFilter.allCases.map { $0.filter }
        capabilities.supportsExceptionFilterOptions = true
        
        capabilities.supportsEvaluateForHovers = true
        capabilities.supportsSetVariable = true
        
        capabilities.supportsCompletionsRequest = true
        capabilities.completionTriggerCharacters = [".", " ", "\t"]
        
        capabilities.supportsRestartRequest = true
        capabilities.supportsExceptionInfoRequest = true
        capabilities.supportTerminateDebuggee = true
        capabilities.supportsTerminateRequest = true
        
        replyHandler(.success(capabilities))
    }
    
    private func listenForEvents() async {
        guard let debugger else {
            return
        }
        
        for await event in debugger.events {
            Task {
                switch event {
                case let .breakpoint(event):
                    await handleBreakpointEvent(event)
                case let .process(event):
                    await handleProcessEvent(event)
                default:
                    break
                }
            }
        }
    }
    
    private var startReplyHandler: ((Result<(), Error>) -> Void)?
    
    private enum DebugRequest {
        case launch(Target.LaunchOptions)
        case attach(Target.AttachOptions)
        
        var shouldTerminateDebuggee: Bool {
            switch self {
            case .launch:
                return true
            case .attach:
                return false
            }
        }
    }
    private var debugRequest: DebugRequest?
    private var isLocal = false
    private var terminateDebuggee = false
    
    struct PathMapping: Sendable, Codable {
        var local: String
        var remote: String
    }
    public private(set) var pathMappings: [PathMapping] = []
    
    private func localPath(forRemotePath path: String) -> String {
        for mapping in pathMappings {
            if path.hasPrefix(mapping.remote) {
                let substring = path[path.index(path.startIndex, offsetBy: mapping.remote.count) ..< path.endIndex]
                return mapping.local.appending(substring)
            }
        }
        return path
    }
    
    private func remotePath(forLocalPath path: String) -> String {
        for mapping in pathMappings {
            if path.hasPrefix(mapping.local) {
                let substring = path[path.index(path.startIndex, offsetBy: mapping.local.count) ..< path.endIndex]
                return mapping.remote.appending(substring)
            }
        }
        return path
    }
    
    private var target: Target?
    private var isWaitingForAttach = false
    private var restartingProcessID: UInt64?
    
    private static let defaultRemotePlatform = "remote-linux"
    
    struct LaunchParameters: Codable {
        var program: String
        var args: [String]?
        var env: [String: String]?
        var cwd: String?
        var arch: String?
        var runInRosetta: Bool?
        var stopOnEntry: Bool?
        
        var initCommands: [String]?
        var preRunCommands: [String]?
        var launchCommands: [String]?
        var stopCommands: [String]?
        var exitCommands: [String]?
        var terminateCommands: [String]?
        
        var port: UInt16?
        var host: String?
        var platform: String?
        var pathMappings: [PathMapping]?
    }
    
    func launch(_ request: DebugAdapter.LaunchRequest<LaunchParameters>, replyHandler: @escaping (Result<(), Error>) -> Void) {
        do {
            try prepareForLaunch(parameters: request.parameters, replyHandler: replyHandler)
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    struct AttachParameters: Codable {
        var program: String?
        var pid: UInt64?
        var waitFor: Bool?
        
        var initCommands: [String]?
        var preRunCommands: [String]?
        var attachCommands: [String]?
        var stopCommands: [String]?
        var exitCommands: [String]?
        var terminateCommands: [String]?
        
        var port: UInt16?
        var host: String?
        var platform: String?
        var pathMappings: [PathMapping]?
    }
    
    func attach(_ request: DebugAdapter.AttachRequest<AttachParameters>, replyHandler: @escaping (Result<(), Error>) -> Void) {
        do {
            try prepareForAttach(parameters: request.parameters, replyHandler: replyHandler)
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    private func prepareForLaunch(parameters: LaunchParameters, replyHandler: @escaping (Result<(), Error>) -> Void) throws {
        guard let debugger else {
            throw AdapterError.invalidParameter("No `initialize` request has been sent.")
        }
        
        var options = Target.LaunchOptions()
        
        options.arguments = parameters.args
        options.environment = parameters.env
        options.workingDirectory = parameters.cwd
        options.stopAtEntry = parameters.stopOnEntry ?? false
        
        var architecture: Architecture?
        if let archString = parameters.arch {
            architecture = Architecture(rawValue: archString)
        }
        else if let runInRosetta = parameters.runInRosetta, runInRosetta {
            architecture = .x86_64
        }
        
        let target: Target
        if let port = parameters.port {
            // Server Port
            let host = parameters.host ?? "localhost"
            let platformName = parameters.platform ?? Self.defaultRemotePlatform
            guard let platform = Platform(named: platformName) else {
                replyHandler(.failure(AdapterError.invalidParameter("Invalid platform “\(platformName)”.")))
                return
            }
            
            output("Connecting to debug server at “\(host):\(port)”…")
            
            try platform.connect(.init(url: "connect://\(host):\(port)"))
            
            debugger.selectedPlatform = platform
            
            target = try debugger.createTarget(path: parameters.program)
            isLocal = false
        }
        else {
            // Path
            target = try debugger.createTarget(path: parameters.program, architecture: architecture ?? .system)
            isLocal = true
        }
        
        debugRequest = .launch(options)
        terminateDebuggee = false
        
        pathMappings = (parameters.pathMappings ?? []).map { mapping in
            var local = mapping.local
            if !local.hasSuffix("/") {
                local = local.appending("/")
            }
            
            var remote = mapping.remote
            if !remote.hasSuffix("/") {
                remote = remote.appending("/")
            }
            
            return PathMapping(local: local, remote: remote)
        }
        
        prepareForStart(target: target, replyHandler: replyHandler)
    }
    
    private func prepareForAttach(parameters: AttachParameters, replyHandler: @escaping (Result<(), Error>) -> Void) throws {
        guard let debugger else {
            throw AdapterError.invalidParameter("No `initialize` request has been sent.")
        }
        
        var options: Target.AttachOptions
        
        let target: Target
        if let port = parameters.port, let path = parameters.program {
            // Server Port
            let host = parameters.host ?? "localhost"
            let platformName = parameters.platform ?? Self.defaultRemotePlatform
            guard let platform = Platform(named: platformName) else {
                replyHandler(.failure(AdapterError.invalidParameter("Invalid platform “\(platformName)”.")))
                return
            }
            
            output("Connecting to debug server at “\(host):\(port)”…")
            
            try platform.connect(.init(url: "connect://\(host):\(port)"))
            
            debugger.selectedPlatform = platform
            
            options = .init(path: path)
            target = try debugger.createTarget(path: path)
            
            isLocal = false
        }
        else if let pid = parameters.pid {
            // PID
            guard let t = debugger.findTarget(processID: pid) else {
                replyHandler(.failure(AdapterError.invalidParameter("Could not find process with pid “\(pid)”.")))
                return
            }
            options = .init(processID: pid)
            target = t
            isLocal = true
        }
        else if let path = parameters.program {
            // Path
            options = .init(path: path)
            target = try debugger.createTarget(path: path)
            isLocal = true
        }
        else {
            replyHandler(.failure(AdapterError.invalidParameter("No process path or pid was provided.")))
            return
        }
        
        options.waitForLaunch = parameters.waitFor ?? false
        
        debugRequest = .attach(options)
        terminateDebuggee = false
        
        pathMappings = (parameters.pathMappings ?? []).map { mapping in
            var local = mapping.local
            if !local.hasSuffix("/") {
                local = local.appending("/")
            }
            
            var remote = mapping.remote
            if !remote.hasSuffix("/") {
                remote = remote.appending("/")
            }
            
            return PathMapping(local: local, remote: remote)
        }
        
        prepareForStart(target: target, replyHandler: replyHandler)
    }
    
    private func prepareForStart(target: Target, replyHandler: @escaping (Result<(), Error>) -> Void) {
        self.startReplyHandler = replyHandler
        self.target = target
        
        // Listen for breakpoint change events from the target.
        debugger?.startListening(to: target, events: [.breakpointChanged])
        
        connection.send(DebugAdapter.InitializedEvent())
    }
    
    func configurationDone(_ request: DebugAdapter.ConfigurationDoneRequest, replyHandler: @escaping (Result<(), Error>) -> Void) {
        guard target != nil else {
            replyHandler(.failure(AdapterError.invalidParameter("No `launch` or `attach` request was sent before `configurationDone`.")))
            return
        }
        replyHandler(.success(()))
        startDebuggee()
    }
    
    private func startDebuggee() {
        guard let debugRequest, let target else {
            return
        }
        
        do {
            switch debugRequest {
            case let .launch(options):
                let process = try target.launch(with: options)
                sendProcessEvent(process, startMethod: .launch)
                
            case let .attach(options):
                let process = try target.attach(with: options)
                if options.waitForLaunch {
                    isWaitingForAttach = true
                }
                else {
                    sendProcessEvent(process, startMethod: .attach)
                }
            }
            
            startReplyHandler?(.success(()))
        }
        catch {
            startReplyHandler?(.failure(error))
        }
        startReplyHandler = nil
    }
    
    private func stopDebuggee(terminate: Bool? = nil) {
        guard let process = target?.process else {
            return
        }
        
        if isWaitingForAttach {
            try? process.stop()
            isWaitingForAttach = false
        }
        else if terminate ?? terminateDebuggee {
            try? process.kill()
        }
        else {
            try? process.detach()
        }
    }
    
    func restart(_ request: DebugAdapter.IncomingRestartRequest<LaunchParameters, AttachParameters>) {
        guard let target else {
            request.reject(throwing: AdapterError.invalidParameter("No `launch` or `attach` request was sent before `configurationDone`."))
            return
        }
        
        restartingProcessID = target.process?.processID
        
        stopDebuggee()
        
        do {
            switch debugRequest {
            case .launch:
                let (request, replyHandler) = try request.decodeForReplyAsLaunch()
                if let arguments = request.arguments {
                    try prepareForLaunch(parameters: arguments, replyHandler: replyHandler)
                }
                else {
                    startReplyHandler = replyHandler
                }
                startDebuggee()
                
            case .attach:
                let (request, replyHandler) = try request.decodeForReplyAsAttach()
                if let arguments = request.arguments {
                    try prepareForAttach(parameters: arguments, replyHandler: replyHandler)
                }
                else {
                    startReplyHandler = replyHandler
                }
                startDebuggee()
                
            default:
                break
            }
        }
        catch {
            request.reject(throwing: error)
        }
    }
    
    func disconnect(_ request: DebugAdapter.DisconnectRequest, replyHandler: @escaping (Result<(), Error>) -> Void) {
        stopDebuggee(terminate: request.terminateDebuggee)
        
        // Clear all breakpoint callbacks.
        Breakpoint.clearAllCallbacks()
        
        if let startReplyHandler {
            self.startReplyHandler = nil
            startReplyHandler(.failure(AdapterError.invalidated))
        }
        
        target = nil
        
        replyHandler(.success(()))
    }
    
    // MARK: - Breakpoints
    
    /**
     * (This idea is directly borrowed from lldb-dap.)
     * 
     * Breakpoints in LLDB can have names added to them which are kind of like
     * labels or categories. All breakpoints that are set through the IDE UI get
     * sent through the various DAP set*Breakpoint packets, and these
     * breakpoints will be labeled with this name so if breakpoint update events
     * come in for breakpoints that the IDE doesn't know about, like if a
     * breakpoint is set manually using the debugger console, we won't report any
     * updates on them and confused the IDE. This function gets called by all of
     * the breakpoint classes after they set breakpoints to mark a breakpoint as
     * a UI breakpoint. We can later check a breakpoint object that comes in via
     * LLDB breakpoint changed events and check the breakpoint by calling
     * `.matchesName(_:)` to check if a breakpoint in one of the UI breakpoints
     * that we should report changes for.
     */
    private static var breakpointLabel = "dap"
    
    private(set) var sourceBreakpoints: [String: [Int: DebugAdapter.SourceBreakpoint]] = [:]
    private(set) var functionBreakpoints: [Int: DebugAdapter.FunctionBreakpoint] = [:]
    private(set) var exceptionFilters: [Int: String] = [:]
    
    @MainActor
    private func handleBreakpointEvent(_ event: BreakpointEvent) {
        switch event.eventType {
        case .locationsAdded, .locationsResolved:
            let bp = event.breakpoint
            if bp.matchesName(Self.breakpointLabel) {
                var breakpoint = DebugAdapter.Breakpoint()
                breakpoint.id = bp.id
                breakpoint.verified = bp.resolvedLocationsCount > 0
                
                if let location = bp.locations.first(where: { $0.isResolved }) ?? bp.locations.first,
                   let address = location.address  {
                    if let lineEntry = address.lineEntry {
                        breakpoint.line = lineEntry.line
                        breakpoint.column = lineEntry.column
                        
                        if let fileSpec = lineEntry.fileSpec,
                           let line = lineEntry.line, line != 0 {
                            // A line entry of 0 indicates the line is compiler generated,
                            // e.g. no source file is associated with the frame.
                            let localPath = localPath(forRemotePath: fileSpec.path)
                            
                            var source = DebugAdapter.Source()
                            source.name = fileSpec.filename
                            source.path = localPath
                            breakpoint.source = source
                        }
                    }
                }
                
                connection.send(DebugAdapter.BreakpointEvent(reason: .changed, breakpoint: breakpoint))
            }
            
        default:
            break
        }
    }
    
    func setBreakpoints(_ request: DebugAdapter.SetBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetBreakpointsRequest.Result, Error>) -> Void) {
        guard let target else {
            replyHandler(.failure(AdapterError.notDebugging))
            return
        }
        
        let source = request.source
        guard let path = source.path else {
            replyHandler(.failure(AdapterError.invalidParameter("Breakpoint source path is missing.")))
            return
        }
        
        // Create new breakpoints
        var breakpoints: [DebugAdapter.Breakpoint] = []
        var newBreakpoints: [Int: DebugAdapter.SourceBreakpoint] = [:]
        var previousBreakpoints = sourceBreakpoints[path] ?? [:]
        
        for sourceBreakpoint in request.breakpoints ?? [] {
            let line = sourceBreakpoint.line
            let column = sourceBreakpoint.column
            
            let matchingBP = previousBreakpoints.first(where: { $0.value.line == line && $0.value.column == column })
            
            let bp: Breakpoint
            if let matchingBP, let breakpoint = target.findBreakpoint(id: matchingBP.key) {
                bp = breakpoint
                previousBreakpoints[matchingBP.key] = nil
            }
            else {
                let resolvedPath = remotePath(forLocalPath: path)
                bp = target.createBreakpoint(path: resolvedPath, line: line, column: column)
                
                // See comments for `Self.breakpointLabel` for details of why we add a label to our breakpoints.
                try? bp.addName(Self.breakpointLabel)
            }
            
            if let condition = sourceBreakpoint.condition {
                bp.condition = condition
            }
            
            var breakpoint = DebugAdapter.Breakpoint()
            breakpoint.id = bp.id
            
            breakpoint.line = line
            breakpoint.column = column
            breakpoint.source = source
            
            breakpoints.append(breakpoint)
            newBreakpoints[bp.id] = sourceBreakpoint
        }
        
        // Update active session
        for (id, _) in previousBreakpoints {
           target.removeBreakpoint(id: id)
        }
        
        sourceBreakpoints[path] = newBreakpoints.count > 0 ? newBreakpoints : nil
        
        replyHandler(.success(.init(breakpoints: breakpoints)))
    }
    
    func setFunctionBreakpoints(_ request: DebugAdapter.SetFunctionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetFunctionBreakpointsRequest.Result, Error>) -> Void) {
        guard let target else {
            replyHandler(.failure(AdapterError.notDebugging))
            return
        }
        
        // Create new breakpoints
        var breakpoints: [DebugAdapter.Breakpoint] = []
        var newFunctionBreakpoints: [Int: DebugAdapter.FunctionBreakpoint] = [:]
        var previousBreakpoints = functionBreakpoints
        
        for functionBreakpoint in request.breakpoints {
            let name = functionBreakpoint.name
            
            let matchingBP = previousBreakpoints.first(where: { $0.value.name == name })
            
            let bp: Breakpoint
            if let matchingBP, let breakpoint = target.findBreakpoint(id: matchingBP.key) {
                bp = breakpoint
                previousBreakpoints[matchingBP.key] = nil
            }
            else {
                bp = target.createBreakpoint(name: name)
                
                // See comments for `Self.breakpointLabel` for details of why we add a label to our breakpoints.
                try? bp.addName(Self.breakpointLabel)
            }
            
            if let condition = functionBreakpoint.condition {
                bp.condition = condition
            }
            
            var breakpoint = DebugAdapter.Breakpoint()
            breakpoint.id = bp.id
            
            breakpoints.append(breakpoint)
            newFunctionBreakpoints[bp.id] = functionBreakpoint
        }
        
        // Update active session
        for (id, _) in previousBreakpoints {
            target.removeBreakpoint(id: id)
        }
        
        functionBreakpoints = newFunctionBreakpoints
        
        replyHandler(.success(.init(breakpoints: breakpoints)))
    }
    
    func setExceptionBreakpoints(_ request: DebugAdapter.SetExceptionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetExceptionBreakpointsRequest.Result?, Error>) -> Void) {
        guard let target else {
            replyHandler(.failure(AdapterError.notDebugging))
            return
        }
        
        var newExceptionFilters: [Int: String] = [:]
        var breakpoints: [DebugAdapter.Breakpoint] = []
        var previousFilters = exceptionFilters
        
        var filterOptions: [DebugAdapter.ExceptionFilterOptions] = []
        filterOptions.append(contentsOf: (request.filters ?? []).map { .init(filterId: $0) })
        filterOptions.append(contentsOf: request.filterOptions ?? [])
        
        for filter in filterOptions {
            let matchingBP = previousFilters.first(where: { $0.value == filter.filterId })
            
            let bp: Breakpoint
            if let matchingBP, let breakpoint = target.findBreakpoint(id: matchingBP.key) {
                bp = breakpoint
                previousFilters[matchingBP.key] = nil
            }
            else if let filter = ExceptionFilter(rawValue: filter.filterId) {
                bp = target.createBreakpoint(forExceptionIn: filter.language, onCatch: filter.isCatch, onThrow: filter.isThrow)
                
                // See comments for `Self.breakpointLabel` for details of why we add a label to our breakpoints.
                try? bp.addName(Self.breakpointLabel)
            }
            else {
                replyHandler(.failure(AdapterError.invalidParameter("Unsupported exception filter: \(filter.filterId).")))
                return
            }
            
            if let condition = filter.condition {
                bp.condition = condition
            }
            
            var breakpoint = DebugAdapter.Breakpoint()
            breakpoint.id = bp.id
            
            breakpoints.append(breakpoint)
            newExceptionFilters[bp.id] = filter.filterId
        }
        
        exceptionFilters = newExceptionFilters
        
        for (id, _) in previousFilters {
            target.removeBreakpoint(id: id)
        }
        
        replyHandler(.success(.init(breakpoints: breakpoints)))
    }
    
    // MARK: - Execution
    
    @MainActor
    private func handleProcessEvent(_ event: ProcessEvent) {
        let process = event.process
        let eventType = event.eventType
        
        if eventType.contains(.stateChanged) {
            let state = event.processState
            switch state {
            case .running:
                willContinue()
                sendContinuedEvent()
                
            case .stopped:
                if isWaitingForAttach {
                    sendProcessEvent(process, startMethod: .attach)
                    isWaitingForAttach = false
                }
                
                if !event.isRestarted {
                    sendStandardOutAndError(process)
                    sendStoppedEvent()
                }
                
            case .exited:
                let processID = process.processID
                if processID == nil || processID == restartingProcessID {
                    restartingProcessID = nil
                }
                else {
                    sendExitedEvent(process)
                    sendTerminatedEvent()
                }
                
            default:
                break
            }
        }
        else if eventType.contains(.standardOut) || eventType.contains(.standardError) {
            sendStandardOutAndError(process)
        }
    }
    
    private func sendStandardOutAndError(_ process: SwiftLLDB.Process) {
        withUnsafeTemporaryAllocation(of: UInt8.self, capacity: 4096) { buffer in
            while true {
                let count = process.readStandardOut(buffer)
                guard count > 0 else {
                    break
                }
                
                if let string = String(bytes: buffer, encoding: .ascii) {
                    output(string, category: .standardOut)
                }
            }
            
            while true {
                let count = process.readStandardError(buffer)
                guard count > 0 else {
                    break
                }
                
                if let string = String(bytes: buffer, encoding: .ascii) {
                    output(string, category: .standardError)
                }
            }
        }
    }
    
    private func sendProcessEvent(_ process: SwiftLLDB.Process, startMethod: DebugAdapter.ProcessEvent.StartMethod) {
        var event = DebugAdapter.ProcessEvent(name: process.info.name)
        event.startMethod = startMethod
        event.isLocalProcess = isLocal
        if let pid = process.processID {
            event.systemProcessId = Int(pid)
        }
        connection.send(event)
    }
    
    private func sendExitedEvent(_ process: SwiftLLDB.Process) {
        let exitCode = Int(process.exitStatus)
        output("Process exited: \(exitCode).")
        connection.send(DebugAdapter.ExitedEvent(exitCode: exitCode))
    }
    
    private func sendContinuedEvent() {
        var event = DebugAdapter.ContinuedEvent(threadId: 0)
        event.allThreadsContinued = true
        connection.send(event)
    }
    
    private func sendStoppedEvent() {
        guard let process = target?.process else {
            return
        }
        
        var thread: SwiftLLDB.Thread?
        
        if let selectedThread = process.selectedThread {
            let stopReason = selectedThread.stopReason
            if stopReason != .invalid && stopReason != .none {
                thread = selectedThread
            }
        }
        
        if thread == nil {
            thread = process.threads.first { thread in
                let stopReason = thread.stopReason
                if stopReason != .invalid && stopReason != .none {
                    process.setSelectedThread(thread)
                    return true
                }
                else {
                    return false
                }
            }
        }
        
        let reason: DebugAdapter.StoppedEvent.Reason
        var hitBreakpointIDs: [Int] = []
        
        if let thread {
            switch thread.stopReason {
                case .breakpoint:
                    reason = .breakpoint
                    
                    let dataCount = thread.stopReasonData.count
                    if dataCount >= 2 {
                        // Breakpoint reason data consists of pairs of [breakpointID, breakpointLocationID].
                        for i in 0 ..< (dataCount / 2) {
                            let id = thread.stopReasonData[i]
                            hitBreakpointIDs.append(Int(id))
                        }
                    }
                    
                case .exception:
                    reason = .exception
                    
                case .trace, .planComplete:
                    reason = .step
                    
                case .signal:
                    reason = .init(rawValue: "signal")
                    
                case .watchpoint:
                    reason = .dataBreakpoint
                    
                default:
                    reason = .init(rawValue: "unknown")
            }
        }
        else {
            reason = .init(rawValue: "unknown")
        }
        
        var event = DebugAdapter.StoppedEvent(reason: reason)
        event.allThreadsStopped = true
        event.threadId = thread?.id
        if !hitBreakpointIDs.isEmpty {
            event.hitBreakpointIds = hitBreakpointIDs
        }
        
        connection.send(event)
    }
    
    private func sendTerminatedEvent() {
        connection.send(DebugAdapter.TerminatedEvent())
    }
    
    private func willContinue() {
        variables.removeAll()
    }
    
    func pause(_ request: DebugAdapter.PauseRequest, replyHandler: @escaping (Result<(), Error>) -> Void) {
        do {
            guard let process = target?.process else {
                throw AdapterError.notDebugging
            }
            
            try process.stop()
            replyHandler(.success(()))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func `continue`(_ request: DebugAdapter.ContinueRequest, replyHandler: @escaping (Result<DebugAdapter.ContinueRequest.Result, Error>) -> Void) {
        do {
            guard let process = target?.process else {
                throw AdapterError.notDebugging
            }
            
            try process.resume()
            
            var result = DebugAdapter.ContinueRequest.Result()
            result.allThreadsContinued = true
            replyHandler(.success(result))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func next(_ request: DebugAdapter.NextRequest, replyHandler: @escaping (Result<(), Error>) -> Void) {
        do {
            guard let process = target?.process else {
                throw AdapterError.notDebugging
            }
            
            let threadID = request.threadId
            guard let thread = process.thread(withID: threadID) else {
                throw AdapterError.invalidParameter("Invalid thread ID “\(threadID)”.")
            }
            
            try thread.stepOver()
            
            replyHandler(.success(()))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func stepIn(_ request: DebugAdapter.StepInRequest, replyHandler: @escaping (Result<(), Error>) -> Void) {
        do {
            guard let process = target?.process else {
                throw AdapterError.notDebugging
            }
            
            let threadID = request.threadId
            guard let thread = process.thread(withID: threadID) else {
                throw AdapterError.invalidParameter("Invalid thread ID “\(threadID)”.")
            }
            
            try thread.stepInto()
            
            replyHandler(.success(()))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func stepOut(_ request: DebugAdapter.StepOutRequest, replyHandler: @escaping (Result<(), Error>) -> Void) {
        do {
            guard let process = target?.process else {
                throw AdapterError.notDebugging
            }
            
            let threadID = request.threadId
            guard let thread = process.thread(withID: threadID) else {
                throw AdapterError.invalidParameter("Invalid thread ID “\(threadID)”.")
            }
            
            try thread.stepOut()
            
            replyHandler(.success(()))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func terminate(_ request: DebugAdapter.TerminateRequest, replyHandler: @escaping (Result<(), Error>) -> Void) {
        do {
            guard let process = target?.process else {
                throw AdapterError.notDebugging
            }
            
            try process.signal(SIGTERM)
            replyHandler(.success(()))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    // MARK: - Threads
    
    private enum VariableContainer {
        case stackFrame(Frame)
        case locals(Frame)
        case globals(Frame)
        case registers(Frame)
        case value(Value)
    }
    private var variables = ReferenceTree<Int, VariableContainer>()
    
    func threads(_ request: DebugAdapter.ThreadsRequest, replyHandler: @escaping (Result<DebugAdapter.ThreadsRequest.Result, Error>) -> Void) {
        guard let process = target?.process else {
            replyHandler(.failure(AdapterError.notDebugging))
            return
        }
        
        let threads = process.threads.map { DebugAdapter.Thread(id: $0.id, name: $0.displayName) }
        
        replyHandler(.success(.init(threads: threads)))
    }
    
    func stackTrace(_ request: DebugAdapter.StackTraceRequest, replyHandler: @escaping (Result<DebugAdapter.StackTraceRequest.Result, Error>) -> Void) {
        guard let process = target?.process else {
            replyHandler(.failure(AdapterError.notDebugging))
            return
        }
        
        let threadID = request.threadId
        guard let thread = process.thread(withID: threadID) else {
            replyHandler(.failure(AdapterError.invalidParameter("Invalid thread ID “\(threadID)”.")))
            return
        }
        
        let frames = thread.frames.enumerated().map { (index, frame) in
            let key = "[\(thread.indexID), \(index)]"
            let ref = variables.insert(parent: nil, key: key, value: .stackFrame(frame))
            
            var debugFrame = DebugAdapter.StackFrame(id: ref)
            
            var name: String
            if let displayName = frame.displayFunctionName {
                name = displayName
            }
            else if let pc = frame.programCounter {
                name = "0x\(String(pc, radix: 16, uppercase: true))"
            }
            else {
                name = "<unknown>"
            }
            
            if frame.function?.isOptimized ?? false {
                name += " [opt]"
            }
            
            debugFrame.name = name
            
            if let lineEntry = frame.lineEntry,
               let fileSpec = lineEntry.fileSpec,
               let line = lineEntry.line, line != 0 {
                // A line entry of 0 indicates the line is compiler generated,
                // e.g. no source file is associated with the frame.
                let localPath = localPath(forRemotePath: fileSpec.path)
                
                var source = DebugAdapter.Source()
                source.name = fileSpec.filename
                source.path = localPath
                debugFrame.source = source
                
                debugFrame.line = line
                debugFrame.column = lineEntry.column
            }
            
            if frame.isArtificial {
                debugFrame.presentationHint = .subtle
            }
            
            if let pc = frame.programCounter {
                debugFrame.instructionPointerReference = "0x\(String(pc, radix: 16, uppercase: true))"
            }
            
            return debugFrame
        }
        
        replyHandler(.success(.init(stackFrames: frames)))
    }
    
    func scopes(_ request: DebugAdapter.ScopesRequest, replyHandler: @escaping (Result<DebugAdapter.ScopesRequest.Result, Error>) -> Void) {
        let frameID = request.frameId
        
        switch variables[frameID] {
            case let .stackFrame(frame):
                let localsRef = variables.insert(parent: frameID, key: "._locals", value: .locals(frame))
                var localsScope = DebugAdapter.Scope(name: "Locals", variablesReference: localsRef)
                localsScope.presentationHint = .locals
                
                let globalsRef = variables.insert(parent: frameID, key: "._globals", value: .globals(frame))
                var globalsScope = DebugAdapter.Scope(name: "Globals", variablesReference: globalsRef)
                globalsScope.presentationHint = .globals
                
                let registersRef = variables.insert(parent: frameID, key: "._registers", value: .registers(frame))
                var registersScope = DebugAdapter.Scope(name: "Registers", variablesReference: registersRef)
                registersScope.presentationHint = .registers
                
                let scopes = [localsScope, globalsScope, registersScope]
                
                replyHandler(.success(.init(scopes: scopes)))
            
            default:
                replyHandler(.failure(AdapterError.invalidParameter("Invalid stack frame ID \(frameID).")))
                return
        }
    }
    
    func variables(_ request: DebugAdapter.VariablesRequest, replyHandler: @escaping (Result<DebugAdapter.VariablesRequest.Result, Error>) -> Void) {
        let ref = request.variablesReference
        
        if let container = variables[ref] {
            switch container {
                case let .locals(frame):
                    let values = frame.variables(for: [.arguments, .locals], inScopeOnly: true)
                    let variables = self.variables(for: values, containerRef: ref, uniquing: true)
                    replyHandler(.success(.init(variables: variables)))
                    
                case let .globals(frame):
                    let values = frame.variables(for: [.statics], inScopeOnly: true)
                    let variables = self.variables(for: values, types: [.global], containerRef: ref, uniquing: false)
                    replyHandler(.success(.init(variables: variables)))
                    
                case let .registers(frame):
                    let values = frame.registers
                    let variables = self.variables(for: values, containerRef: ref, uniquing: false)
                    replyHandler(.success(.init(variables: variables)))
                    
                case let .value(value):
                    let variables = self.variables(for: value.children, containerRef: ref, uniquing: false)
                    replyHandler(.success(.init(variables: variables)))
                
                case .stackFrame(_):
                    replyHandler(.success(.init(variables: [])))
            }
        }
        else {
            replyHandler(.failure(AdapterError.invalidParameter("Invalid variables reference: \(ref).")))
        }
    }
    
    private func variables<S>(for values: S, types: Set<Value.ValueType>? = nil, containerRef: Int, uniquing: Bool) -> [DebugAdapter.Variable] where S: Sequence, S.Element == Value {
        var variables: [DebugAdapter.Variable] = []
        var variablesIndexesByName: [String: Int] = [:]
        
        for value in values {
            guard let name = value.name else {
                continue
            }
            
            if !(types?.contains(value.valueType) ?? true) {
                continue
            }
            
            let summary = value.summary ?? value.value ?? ""
            
            var variable = DebugAdapter.Variable(name: name, value: summary)
            
            variable.type = value.displayTypeName
            variable.variablesReference = variableReference(for: value, key: name, parent: containerRef)
            
            if uniquing {
                if let index = variablesIndexesByName[name] {
                    variables[index] = variable
                }
                else {
                    variablesIndexesByName[name] = variables.count
                    variables.append(variable)
                }
            }
            else {
                variables.append(variable)
            }
        }
        
        return variables;
    }
    
    private func variableReference(for value: Value, key: String, parent: Int?) -> Int? {
        guard !value.children.isEmpty && !value.isSynthetic else {
            return nil
        }
        return variables.insert(parent: parent, key: key, value: .value(value))
    }
    
    func completions(_ request: DebugAdapter.CompletionsRequest, replyHandler: @escaping (Result<DebugAdapter.CompletionsRequest.Result, Error>) -> Void) {
        do {
            guard let debugger else {
                throw AdapterError.notDebugging
            }
            
            let text = request.text
            
            if let first = text.first, !first.isLetter && !first.isNumber {
                // LLDB can crash if the first character of the expression is non-alphanumeric.
                replyHandler(.success(.init(targets: [])))
                return
            }
            
            var column = request.column
            if clientOptions.columnsStartAt1, column > 0 {
                column -= 1
            }
            
            // Translate the UTF-16 offset to UTF-8 byte offset
            let cursorIndex = text.utf16.index(text.startIndex, offsetBy: column)
            let cursorPosition = text.unicodeScalars.distance(from: text.startIndex, to: cursorIndex)
            
            let interpreter = debugger.commandInterpreter
            let strings = interpreter.handleCompletions(text, cursorPosition: cursorPosition, matchStart: 0)
            
            let targets: [DebugAdapter.CompletionItem] = strings.compactMap { string in
                return nil
            }
            
            replyHandler(.success(.init(targets: targets)))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func evaluate(_ request: DebugAdapter.EvaluateRequest, replyHandler: @escaping (Result<DebugAdapter.EvaluateRequest.Result, Error>) -> Void) {
        do {
            var frame: Frame?
            if let frameID = request.frameId,
               case let .stackFrame(f) = variables[frameID] {
                frame = f
            }
            
            let expression = request.expression
            
            let result: DebugAdapter.EvaluateRequest.Result
            if let context = request.context {
                switch context {
                case .repl:
                    if let hookRange = expression.range(of: "?", options: [.anchored]) {
                        let substring = String(expression[hookRange.upperBound...])
                        result = try evaluateExpression(substring, frame: frame)
                    }
                    else {
                        result = try executeCommand(expression, frame: frame)
                    }
                    
                default:
                    result = try evaluateExpression(expression, frame: frame)
                }
            }
            else {
                result = try evaluateExpression(expression, frame: frame)
            }
            
            replyHandler(.success(result))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    private func executionContext(for frame: Frame?) throws -> ExecutionContext {
        if let frame {
            return ExecutionContext(from: frame)
        }
        else {
            guard let process = target?.process else {
                throw AdapterError.notDebugging
            }
            
            if let thread = process.selectedThread {
                return ExecutionContext(from: thread)
            }
            else {
                return ExecutionContext(from: process)
            }
        }
    }
    
    private func executeCommand(_ expression: String, frame: Frame?) throws -> DebugAdapter.EvaluateRequest.Result {
        guard let debugger else {
            throw AdapterError.notDebugging
        }
        
        let interpreter = debugger.commandInterpreter
        let context = try executionContext(for: frame)
        let result = try interpreter.handleCommand(expression, context: context, addToHistory: false)
        
        return .init(result: result.output ?? "")
    }
    
    private func evaluateExpression(_ expression: String, frame: Frame?) throws -> DebugAdapter.EvaluateRequest.Result {
        let result: Value
        if let frame {
            result = try frame.evaluate(expression: expression)
        }
        else {
            guard let target else {
                throw AdapterError.notDebugging
            }
            result = try target.evaluate(expression: expression)
        }
        
        let summary = result.summary ?? result.value ?? ""
        
        var requestResult = DebugAdapter.EvaluateRequest.Result(result: summary)
        requestResult.type = result.displayTypeName
        requestResult.variablesReference = variableReference(for: result, key: expression, parent: nil) ?? 0
        
        return requestResult
    }
    
    func setVariable(_ request: DebugAdapter.SetVariableRequest, replyHandler: @escaping (Result<DebugAdapter.SetVariableRequest.Result, Error>) -> Void) {
        do {
            let name = request.name
            let ref = request.variablesReference
            
            let child: Value?
            switch variables[ref] {
            case let .value(value):
                child = value.childMember(named: name)
            case let .locals(frame), let .globals(frame):
                child = frame.findVariable(named: name)
            default:
                child = nil
            }
            
            guard let child, let childName = child.name else {
                throw AdapterError.invalidParameter("Unable to set variable value “\(name)”.")
            }
            
            let value = request.value
            try child.setValue(value)
            
            let summary = child.summary ?? child.value ?? ""
            
            var result = DebugAdapter.SetVariableRequest.Result(value: summary)
            result.type = child.displayTypeName
            result.variablesReference = variableReference(for: child, key: childName, parent: ref)
            
            replyHandler(.success(result))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
}
