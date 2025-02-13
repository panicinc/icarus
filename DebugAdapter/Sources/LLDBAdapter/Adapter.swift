import Darwin
import Dispatch
import RegexBuilder
import Foundation
import SwiftLLDB

final class Adapter: DebugAdapterServerRequestHandler {
    static let shared = Adapter()
    
    let connection = DebugAdapterConnection(transport: DebugAdapterFileHandleTransport())
    
    // MARK: - Lifecycle
    
    private var isRunning = false
    private var debugger: Debugger?
    private var eventsTask: Task<(), Never>?
    
    func resume() {
        guard !isRunning else {
            return
        }
        isRunning = true
        
        signal(SIGINT) { _ in Adapter.shared.shutdown() }
        signal(SIGTERM) { _ in Adapter.shared.shutdown() }
        
        var configuration = DebugAdapterConnection.Configuration()
        configuration.messageQueue = .main
        configuration.invalidationHandler = { [weak self] error in
            self?.shutdown(error: error)
        }
        configuration.requestHandler = self
        
        connection.setConfiguration(configuration)
        connection.start()
        
        dispatchMain()
    }
    
    func shutdown(error: Error? = nil) {
        guard isRunning else {
            return
        }
        isRunning = false
        
        eventsTask?.cancel()
        eventsTask = nil
        
        target = nil
        debugger = nil
        
        connection.stop()
        
        exit(error != nil ? EXIT_FAILURE : EXIT_SUCCESS)
    }
    
    func handleRequest(_ request: DebugAdapterConnection.IncomingRequest) {
        do {
            switch request.command {
                
            default:
                try performDefaultHandling(for: request)
            }
        }
        catch {
            request.reject(throwing: error)
        }
    }
    
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
        
        var label: String {
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
            var filter = DebugAdapter.ExceptionBreakpointFilter(filter: rawValue, label: label)
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
        capabilities.supportsDataBreakpoints = true
        capabilities.supportsDataBreakpointBytes = true
        capabilities.supportsInstructionBreakpoints = true
        
        capabilities.exceptionBreakpointFilters = ExceptionFilter.allCases.map { $0.filter }
        capabilities.supportsExceptionFilterOptions = true
        
        capabilities.supportsSteppingGranularity = true
        capabilities.supportsRestartRequest = true
        capabilities.supportsExceptionInfoRequest = true
        capabilities.supportTerminateDebuggee = true
        capabilities.supportsTerminateRequest = true
        capabilities.supportsReadMemoryRequest = true
        capabilities.supportsWriteMemoryRequest = true
        
        capabilities.supportsCompletionsRequest = true
        capabilities.completionTriggerCharacters = [".", " ", "\t"]
        
        capabilities.supportsEvaluateForHovers = true
        capabilities.supportsSetVariable = true
        capabilities.supportsANSIStyling = true
        
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
            if let r = path.range(of: mapping.remote, options: [.anchored]) {
                return mapping.local.appending(path[r.upperBound...])
            }
        }
        return path
    }
    
    private func remotePath(forLocalPath path: String) -> String {
        for mapping in pathMappings {
            if let r = path.range(of: mapping.local, options: [.anchored]) {
                return mapping.remote.appending(path[r.upperBound...])
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
    
    func restart(_ request: DebugAdapter.IncomingRestartRequest<LaunchParameters, AttachParameters>) {
        do {
            guard let target else {
                throw AdapterError.notDebugging
            }
            
            // Stop the current process if necessary.
            if let process = target.process {
                restartingProcessID = process.processID
                
                if process.state != .connected {
                    try? process.kill()
                }
            }
            else {
                restartingProcessID = nil
            }
            
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
        if let process = target?.process {
            switch process.state {
            case .invalid,
                .unloaded,
                .detached,
                .exited:
                break
            case .connected,
                .attaching,
                .launching,
                .stepping,
                .crashed,
                .suspended,
                .stopped,
                .running:
                if isWaitingForAttach {
                    try? process.stop()
                }
                
                if request.terminateDebuggee ?? terminateDebuggee {
                    try? process.kill()
                }
                else {
                    try? process.detach()
                }
            default:
                break
            }
        }
        
        replyHandler(.success(()))
        
        shutdown()
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
    
    private var sourceBreakpoints: [SourceReference: [Int: DebugAdapter.SourceBreakpoint]] = [:]
    private var functionBreakpoints: [Int: DebugAdapter.FunctionBreakpoint] = [:]
    private var instructionBreakpoints: [Int: DebugAdapter.InstructionBreakpoint] = [:]
    private var dataBreakpoints: [Int: DebugAdapter.DataBreakpoint] = [:]
    private var exceptionBreakpoints: [Int: ExceptionFilter] = [:]
    
    private func adapterBreakpoint(for breakpoint: SwiftLLDB.Breakpoint) -> DebugAdapter.Breakpoint {
        var result = DebugAdapter.Breakpoint(id: breakpoint.id)
        
        result.verified = breakpoint.resolvedLocationsCount > 0
        
        if let location = breakpoint.locations.first(where: { $0.isResolved }) ?? breakpoint.locations.first,
           let address = location.address,
           let lineEntry = address.lineEntry,
           let fileSpec = lineEntry.fileSpec,
           let line = lineEntry.line, line > 0 {
               // A zero-value line means the source is compiler generated.
            result.instructionReference = formatAddress(address.loadAddress(for: breakpoint.target))
            
            result.source = adapterSource(for: fileSpec)
            result.line = clientOptions.linesStartAt1 ? line : line - 1
            if let column = lineEntry.column {
                result.column = clientOptions.columnsStartAt1 ? column : column - 1
            }
        }
        
        return result
    }
    
    @MainActor
    private func handleBreakpointEvent(_ event: BreakpointEvent) {
        switch event.eventType {
        case .locationsAdded, .locationsResolved:
            let breakpoint = event.breakpoint
            if breakpoint.matchesName(Self.breakpointLabel) {
                connection.send(DebugAdapter.BreakpointEvent(reason: .changed, breakpoint: adapterBreakpoint(for: breakpoint)))
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
        
        let ref: SourceReference
        if let path = source.path {
            ref = .path(path)
        }
        else if let reference = source.sourceReference {
            ref = .ref(reference)
        }
        else {
            replyHandler(.failure(AdapterError.invalidParameter("Missing required parameter “source.path” or “source.sourceReference”.")))
            return
        }
        
        var results: [DebugAdapter.Breakpoint] = []
        var newBreakpoints: [Int: DebugAdapter.SourceBreakpoint] = [:]
        var previousBreakpoints = sourceBreakpoints[ref] ?? [:]
        
        for sourceBreakpoint in request.breakpoints ?? [] {
            let line = sourceBreakpoint.line
            let column = sourceBreakpoint.column
            
            do {
                let breakpoint: Breakpoint
                if let match = previousBreakpoints.first(where: { $0.value.line == line && $0.value.column == column }),
                let bp = target.findBreakpoint(id: match.key) {
                    breakpoint = bp
                    previousBreakpoints[match.key] = nil
                }
                else {
                    switch ref {
                    case .path(let path):
                        let resolvedPath = remotePath(forLocalPath: path)
                        breakpoint = target.createBreakpoint(path: resolvedPath, line: line, column: column)
                    case .ref(let reference):
                        throw AdapterError.invalidParameter("Invalid source reference: “\(reference)”.")
                    }
                    
                    // See comments for `Self.breakpointLabel` for details of why we add a label to our breakpoints.
                    try? breakpoint.addName(Self.breakpointLabel)
                }
                
                breakpoint.condition = sourceBreakpoint.condition
                
                let result = adapterBreakpoint(for: breakpoint)
                
                newBreakpoints[breakpoint.id] = sourceBreakpoint
                results.append(result)
            }
            catch {
                let result = DebugAdapter.Breakpoint(verified: false, reason: .failed)
                results.append(result)
            }
        }
        
        for (id, _) in previousBreakpoints {
           target.removeBreakpoint(id: id)
        }
        
        sourceBreakpoints[ref] = newBreakpoints.count > 0 ? newBreakpoints : nil
        
        replyHandler(.success(.init(breakpoints: results)))
    }
    
    func setFunctionBreakpoints(_ request: DebugAdapter.SetFunctionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetFunctionBreakpointsRequest.Result, Error>) -> Void) {
        guard let target else {
            replyHandler(.failure(AdapterError.notDebugging))
            return
        }
        
        var results: [DebugAdapter.Breakpoint] = []
        var newBreakpoints: [Int: DebugAdapter.FunctionBreakpoint] = [:]
        var previousBreakpoints = functionBreakpoints
        
        for functionBreakpoint in request.breakpoints {
            let name = functionBreakpoint.name
            
            let breakpoint: Breakpoint
            if let match = previousBreakpoints.first(where: { $0.value.name == name }),
                let bp = target.findBreakpoint(id: match.key) {
                breakpoint = bp
                previousBreakpoints[match.key] = nil
            }
            else {
                breakpoint = target.createBreakpoint(name: name)
                
                // See comments for `Self.breakpointLabel` for details of why we add a label to our breakpoints.
                try? breakpoint.addName(Self.breakpointLabel)
            }
            
            breakpoint.condition = functionBreakpoint.condition
            
            let result = adapterBreakpoint(for: breakpoint)
            
            newBreakpoints[breakpoint.id] = functionBreakpoint
            results.append(result)
        }
        
        for (id, _) in previousBreakpoints {
            target.removeBreakpoint(id: id)
        }
        
        functionBreakpoints = newBreakpoints
        
        replyHandler(.success(.init(breakpoints: results)))
    }
    
    func setInstructionBreakpoints(_ request: DebugAdapter.SetInstructionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetInstructionBreakpointsRequest.Result, Error>) -> Void) {
        guard let target else {
            replyHandler(.failure(AdapterError.notDebugging))
            return
        }
        
        var results: [DebugAdapter.Breakpoint] = []
        var newBreakpoints: [Int: DebugAdapter.InstructionBreakpoint] = [:]
        var previousBreakpoints = instructionBreakpoints
        
        for instructionBreakpoint in request.breakpoints {
            do {
                let ref = instructionBreakpoint.instructionReference
                guard let addr = self.parseAddress(from: ref) else {
                    throw AdapterError.invalidParameter("Invalid memory reference “\(instructionBreakpoint.instructionReference)”.")
                }
                
                let breakpoint: Breakpoint
                if let match = previousBreakpoints.first(where: { $0.value.instructionReference == ref }),
                   let bp = target.findBreakpoint(id: match.key) {
                    breakpoint = bp
                    previousBreakpoints[match.key] = nil
                }
                else {
                    breakpoint = target.createBreakpoint(address: addr)
                    
                    // See comments for `Self.breakpointLabel` for details of why we add a label to our breakpoints.
                    try? breakpoint.addName(Self.breakpointLabel)
                }
                
                breakpoint.condition = instructionBreakpoint.condition
                
                let result = adapterBreakpoint(for: breakpoint)
                
                newBreakpoints[breakpoint.id] = instructionBreakpoint
                results.append(result)
            }
            catch {
                let result = DebugAdapter.Breakpoint(verified: false, reason: .failed)
                results.append(result)
            }
        }
        
        for (id, _) in previousBreakpoints {
            target.removeBreakpoint(id: id)
        }
        
        instructionBreakpoints = newBreakpoints
        
        replyHandler(.success(.init(breakpoints: results)))
    }
    
    func dataBreakpointInfo(_ request: DebugAdapter.DataBreakpointInfoRequest, replyHandler: @escaping (Result<DebugAdapter.DataBreakpointInfoRequest.Result, Error>) -> Void) {
        do {
            let name = request.name
            
            if request.asAddress ?? false {
                // Address
                guard let addr = self.parseAddress(from: name) else {
                    throw AdapterError.invalidParameter("Invalid memory reference “\(name)”.")
                }
                guard let bytes = request.bytes else {
                    throw AdapterError.invalidParameter("Missing required parameter “bytes”.")
                }
                
                let addrStr = String(addr, radix: 16, uppercase: true)
                let bytesStr = String(bytes)
                let dataId = "\(addrStr)/\(bytesStr)"
                let desc = "\(bytesStr) bytes at \(addrStr)"
                
                var result = DebugAdapter.DataBreakpointInfoRequest.Result(dataId: dataId, description: desc)
                result.accessTypes = [.read, .write, .readWrite]
                
                replyHandler(.success(result))
            }
            else if let ref = request.variablesReference {
                // Variable reference
                guard let value = try findVariableValue(named: name, in: ref) else {
                    throw AdapterError.invalidParameter("Value “\(name)” not found.")
                }
                guard let addr = value.loadAddress else {
                    throw AdapterError.invalidParameter("Value “\(name)” does not exist in memory; its location is “\(String(describing: value.location))”.")
                }
                
                let bytes = request.bytes ?? value.byteSize
                if bytes == 0 {
                    throw AdapterError.invalidParameter("Value “\(name)” has zero-size in memory.")
                }
                
                let addrStr = String(addr, radix: 16, uppercase: true)
                let bytesStr = String(bytes)
                let dataId = "\(addrStr)/\(bytesStr)"
                let desc = "\(bytesStr) bytes at \(addrStr)"
                
                var result = DebugAdapter.DataBreakpointInfoRequest.Result(dataId: dataId, description: desc)
                result.accessTypes = [.read, .write, .readWrite]
                
                replyHandler(.success(result))
            }
            else {
                // Expression
                guard let target, let process = target.process else {
                    throw AdapterError.notDebugging
                }
                let frame = try request.frameId.flatMap { try self.frame(withID: $0) }
                
                let value: Value
                if let frame {
                    value = try frame.evaluate(expression: name)
                }
                else {
                    value = try target.evaluate(expression: name)
                }
                
                guard let addr = value.valueAsAddress else {
                    throw AdapterError.invalidParameter("Value “\(name)” does not exist in memory; its location is “\(String(describing: value.location))”.")
                }
                guard let data = value.pointeeData() else {
                    throw AdapterError.invalidParameter("Value “\(name)” has zero-size in memory.")
                }
                
                let bytes = request.bytes ?? data.byteSize
                
                if let region = try? process.memoryRegionInfo(at: addr),
                    !region.isReadable || !region.isWritable {
                    throw AdapterError.invalidParameter("Memory region for “\(name)” has no read or write access.")
                }
                
                let addrStr = String(addr, radix: 16, uppercase: true)
                let bytesStr = String(bytes)
                let dataId = "\(addrStr)/\(bytesStr)"
                let desc = "\(bytesStr) bytes at \(addrStr)"
                
                var result = DebugAdapter.DataBreakpointInfoRequest.Result(dataId: dataId, description: desc)
                result.accessTypes = [.read, .write, .readWrite]
                
                replyHandler(.success(result))
            }
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func setDataBreakpoints(_ request: DebugAdapter.SetDataBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetDataBreakpointsRequest.Result, Error>) -> Void) {
        guard let target else {
            replyHandler(.failure(AdapterError.notDebugging))
            return
        }
        
        var results: [DebugAdapter.Breakpoint] = []
        var newBreakpoints: [Int: DebugAdapter.DataBreakpoint] = [:]
        var previousBreakpoints = dataBreakpoints
        
        for dataBreakpoint in request.breakpoints {
            let dataId = dataBreakpoint.dataId
            let accessType = dataBreakpoint.accessType
            
            do {
                let watchpoint: Watchpoint
                if let match = previousBreakpoints.first(where: { $0.value.dataId == dataId && $0.value.accessType == accessType }),
                   let wp = target.findWatchpoint(id: match.key) {
                    watchpoint = wp
                    previousBreakpoints[match.key] = nil
                }
                else {
                    let comps = dataId.split(separator: "/", maxSplits: 1)
                    guard comps.count == 2,
                        let addr = UInt64(comps[0], radix: 16),
                        let size = Int(comps[1]) else {
                        throw AdapterError.invalidParameter("Invalid data breakpoint dataId “\(dataId)”.")
                    }
                    
                    let onRead = accessType != .write
                    let onWrite = accessType != .read
                    
                    watchpoint = try target.createWatchpoint(at: addr, count: size, onRead: onRead, onWrite: onWrite)
                }
                
                watchpoint.condition = dataBreakpoint.condition
                
                let result = DebugAdapter.Breakpoint(id: watchpoint.id, verified: true)
                
                newBreakpoints[watchpoint.id] = dataBreakpoint
                results.append(result)
            }
            catch {
                let result = DebugAdapter.Breakpoint(verified: false, reason: .failed)
                results.append(result)
            }
        }
        
        for (id, _) in previousBreakpoints {
            target.removeWatchpoint(id: id)
        }
        
        dataBreakpoints = newBreakpoints
        
        replyHandler(.success(.init(breakpoints: results)))
    }
    
    func setExceptionBreakpoints(_ request: DebugAdapter.SetExceptionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetExceptionBreakpointsRequest.Result?, Error>) -> Void) {
        guard let target else {
            replyHandler(.failure(AdapterError.notDebugging))
            return
        }
        
        var results: [DebugAdapter.Breakpoint] = []
        var newBreakpoints: [Int: ExceptionFilter] = [:]
        var previousBreakpoints = exceptionBreakpoints
        
        var filterOptions: [DebugAdapter.ExceptionFilterOptions] = []
        filterOptions.append(contentsOf: (request.filters ?? []).map { .init(filterId: $0) })
        filterOptions.append(contentsOf: request.filterOptions ?? [])
        
        for options in filterOptions {
            let filter: ExceptionFilter
            let breakpoint: Breakpoint
            if let match = previousBreakpoints.first(where: { $0.value.rawValue == options.filterId }),
               let bp = target.findBreakpoint(id: match.key) {
                filter = match.value
                breakpoint = bp
                previousBreakpoints[match.key] = nil
            }
            else if let f = ExceptionFilter(rawValue: options.filterId) {
                filter = f
                breakpoint = target.createBreakpoint(forExceptionIn: filter.language, onCatch: filter.isCatch, onThrow: filter.isThrow)
                
                // See comments for `Self.breakpointLabel` for details of why we add a label to our breakpoints.
                try? breakpoint.addName(Self.breakpointLabel)
            }
            else {
                replyHandler(.failure(AdapterError.invalidParameter("Unsupported exception filter “\(options.filterId)”.")))
                return
            }
            
            breakpoint.condition = options.condition
            
            let result = adapterBreakpoint(for: breakpoint)
            
            newBreakpoints[breakpoint.id] = filter
            results.append(result)
        }
        
        exceptionBreakpoints = newBreakpoints
        
        for (id, _) in previousBreakpoints {
            target.removeBreakpoint(id: id)
        }
        
        replyHandler(.success(.init(breakpoints: results)))
    }
    
    // MARK: - Sources and Variables
    
    enum SourceReference: Hashable {
        case path(String)
        case ref(Int)
    }
    
    private func adapterSource(for fileSpec: FileSpec) -> DebugAdapter.Source {
        var source = DebugAdapter.Source()
        source.name = fileSpec.filename
        source.path = localPath(forRemotePath: fileSpec.path)
        return source
    }
    
    private enum VariableContainer {
        case stackFrame(Frame)
        case locals(Frame)
        case globals(Frame)
        case registers(Frame)
        case value(Value)
    }
    private var variables = ReferenceTree<Int, VariableContainer>()
    
    private func findVariableValue(named name: String, in ref: Int) throws -> Value? {
        guard let container = variables[ref] else {
            throw AdapterError.invalidParameter("Invalid variable reference “\(ref)”.")
        }
        
        switch container {
            case let .locals(frame),
                let .globals(frame),
                let .registers(frame):
                return frame.findVariable(named: name)
                
            case let .value(value):
                return value.childMember(named: name)
            
            case .stackFrame(_):
                return nil
        }
    }
    
    private func variables(for ref: Int) throws -> [DebugAdapter.Variable] {
        guard let container = variables[ref] else {
            throw AdapterError.invalidParameter("Invalid variable reference “\(ref)”.")
        }
        
        switch container {
            case let .locals(frame):
                let values = frame.variables(for: [.arguments, .locals], inScopeOnly: true)
                return self.variables(for: values, containerRef: ref, uniquing: true)
                
            case let .globals(frame):
                let values = frame.variables(for: [.statics], inScopeOnly: true)
                return self.variables(for: values, types: [.global], containerRef: ref, uniquing: false)
                
            case let .registers(frame):
                let values = frame.registers
                return self.variables(for: values, containerRef: ref, uniquing: false)
                
            case let .value(value):
                return self.variables(for: value.children, containerRef: ref, uniquing: false)
            
            case .stackFrame(_):
                return []
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
    
    private func parseAddress(from string: String) -> UInt64? {
        if let r = string.range(of: "0x", options: [.anchored]) {
            // Hexadecimal
            return UInt64(string[r.upperBound...], radix: 16)
        }
        else {
            // Decimal
            return UInt64(string)
        }
    }
    
    private func formatAddress(_ address: UInt64) -> String {
        return String(address, radix: 16, uppercase: true)
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
                    sendThreadStoppedEvent()
                }
                
            case .exited:
                let processID = process.processID
                if processID == nil || processID == restartingProcessID {
                    restartingProcessID = nil
                }
                else {
                    sendProcessExitedEvent(process)
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
        withUnsafeTemporaryAllocation(of: CChar.self, capacity: 4096) { buffer in
            while true {
                let count = process.readStandardOut(buffer)
                guard count > 0 else {
                    break
                }
                
                let string = buffer[0 ..< count].withMemoryRebound(to: UInt8.self) { asciiBuffer in
                    String(decoding: asciiBuffer, as: Unicode.ASCII.self)
                }
                output(string, category: .standardOutput)
            }
            
            while true {
                let count = process.readStandardError(buffer)
                guard count > 0 else {
                    break
                }
                
                let string = buffer[0 ..< count].withMemoryRebound(to: UInt8.self) { asciiBuffer in
                    String(decoding: asciiBuffer, as: Unicode.ASCII.self)
                }
                output(string, category: .standardError)
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
    
    private func sendProcessExitedEvent(_ process: SwiftLLDB.Process) {
        connection.send(DebugAdapter.ExitedEvent(exitCode: Int(process.exitStatus)))
    }
    
    private func sendThreadExitedEvent(_ thread: SwiftLLDB.Thread) {
        connection.send(DebugAdapter.ThreadEvent(threadId: thread.id, reason: .exited))
    }
    
    private func sendThreadStoppedEvent() {
        guard let process = target?.process else {
            return
        }
        
        var thread: SwiftLLDB.Thread?
        
        if let selectedThread = process.selectedThread, selectedThread.hasValidStopReason {
            thread = selectedThread
        }
        
        if thread == nil {
            thread = process.threads.first { $0.hasValidStopReason }
        }
        
        let reason: DebugAdapter.StoppedEvent.Reason
        
        var hitBreakpointIDs: [Int]?
        if let thread {
            switch thread.stopReason {
                case .breakpoint(let ids):
                    if ids.first(where: { instructionBreakpoints[$0] != nil }) != nil {
                        reason = .instructionBreakpoint
                    }
                    else {
                        reason = .breakpoint
                    }
                    hitBreakpointIDs = ids
                case .watchpoint(let id):
                    reason = .dataBreakpoint
                    hitBreakpointIDs = [id]
                case .exception:
                    reason = .exception
                case .signal:
                    reason = "signal"
                case .trace, .planComplete:
                    reason = .step
                default:
                    reason = "unknown"
            }
        }
        else {
            reason = "unknown"
        }
        
        var event = DebugAdapter.StoppedEvent(reason: reason)
        event.allThreadsStopped = true
        event.threadId = thread?.id
        event.hitBreakpointIds = hitBreakpointIDs
        
        connection.send(event)
    }
    
    private func sendContinuedEvent() {
        var event = DebugAdapter.ContinuedEvent(threadId: 0)
        event.allThreadsContinued = true
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
            
            if request.granularity == .instruction {
                try thread.stepOverInstruction()
            }
            else {
                try thread.stepOver()
            }
            
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
            
            if request.granularity == .instruction {
                try thread.stepIntoInstruction()
            }
            else {
                try thread.stepInto()
            }
            
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
    
    func threads(_ request: DebugAdapter.ThreadsRequest, replyHandler: @escaping (Result<DebugAdapter.ThreadsRequest.Result, Error>) -> Void) {
        guard let process = target?.process else {
            replyHandler(.failure(AdapterError.notDebugging))
            return
        }
        
        let threads = process.threads.map { DebugAdapter.Thread(id: $0.id, name: $0.displayName, description: $0.queueDisplayName) }
        
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
                name = formatAddress(pc)
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
                // A zero-value line means the source is compiler generated.
                debugFrame.source = adapterSource(for: fileSpec)
                
                debugFrame.line = clientOptions.linesStartAt1 ? line : line - 1
                
                if let column = lineEntry.column {
                    debugFrame.column = clientOptions.columnsStartAt1 ? column : column - 1
                }
            }
            
            if frame.isArtificial {
                debugFrame.presentationHint = .subtle
            }
            
            if let pc = frame.programCounter {
                debugFrame.instructionPointerReference = formatAddress(pc)
            }
            
            var attributes: [DebugAdapter.StackFrame.Attribute] = []
            
            if let data = frame.languageSpecificData {
                if data["IsSwiftAsyncFunction"]?.asBool() ?? false {
                    attributes.append(.async)
                }
            }
            
            debugFrame.attributes = attributes
            
            return debugFrame
        }
        
        replyHandler(.success(.init(stackFrames: frames)))
    }
    
    private func frame(withID id: Int) throws -> Frame {
        guard case let .stackFrame(frame) = variables[id] else {
            throw AdapterError.invalidParameter("Invalid stack frame ID “\(id)”.")
        }
        return frame
    }
    
    func exceptionInfo(_ request: DebugAdapter.ExceptionInfoRequest, replyHandler: @escaping (Result<DebugAdapter.ExceptionInfoRequest.Result, Error>) -> Void) {
        guard let process = target?.process else {
            replyHandler(.failure(AdapterError.notDebugging))
            return
        }
        
        let threadID = request.threadId
        guard let thread = process.thread(withID: threadID) else {
            replyHandler(.failure(AdapterError.invalidParameter("Invalid thread ID “\(threadID)”.")))
            return
        }
        
        let exceptionID: String
        var description: String?
        
        switch thread.stopReason {
        case .signal:
            exceptionID = "signal"
            
        case .breakpoint(let ids):
            if let id = ids.first(where: { exceptionBreakpoints[$0] != nil }),
               let breakpoint = exceptionBreakpoints[id] {
                exceptionID = breakpoint.rawValue
                description = breakpoint.label
            }
            else {
                exceptionID = "exception"
            }
            
        default:
            exceptionID = "exception"
        }
        
        var result = DebugAdapter.ExceptionInfoRequest.Result(exceptionId: exceptionID, breakMode: .always)
        result.description = description
        
        if let exception = thread.currentException {
            var details = DebugAdapter.ExceptionDetails()
            
            details.message = exception.description
            
            if let backtrace = thread.currentExceptionBacktrace {
                var stackTrace = backtrace.description ?? ""
                for frame in backtrace.frames {
                    stackTrace.append(frame.description ?? "")
                }
                details.stackTrace = stackTrace
            }
            
            result.details = details
        }
        
        replyHandler(.success(result))
    }
    
    func scopes(_ request: DebugAdapter.ScopesRequest, replyHandler: @escaping (Result<DebugAdapter.ScopesRequest.Result, Error>) -> Void) {
        do {
            let frameID = request.frameId
            let frame = try self.frame(withID: frameID)
            
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
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func variables(_ request: DebugAdapter.VariablesRequest, replyHandler: @escaping (Result<DebugAdapter.VariablesRequest.Result, Error>) -> Void) {
        do {
            let variables = try self.variables(for: request.variablesReference)
            replyHandler(.success(.init(variables: variables)))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func completions(_ request: DebugAdapter.CompletionsRequest, replyHandler: @escaping (Result<DebugAdapter.CompletionsRequest.Result, Error>) -> Void) {
        do {
            guard let debugger else {
                throw AdapterError.notDebugging
            }
            
            let frame = try request.frameId.flatMap { try self.frame(withID: $0) }
            if let frame {
                let thread = frame.thread
                let process = thread.process
                process.setSelectedThread(thread)
                thread.setSelectedFrame(at: frame.id)
            }
            
            let text = request.text
            
            let line = max(clientOptions.linesStartAt1 ? (request.line ?? 1) - 1 : request.line ?? 0, 0)
            let column = max(clientOptions.columnsStartAt1 ? request.column - 1 : request.column, 0)
            
            if line > 0 {
                
            }
            
            // Translate the UTF-16 offset to UTF-8 byte offset
            let cursorIndex = String.Index(utf16Offset: column, in: text)
            let cursorPosition = text.utf8.distance(from: text.startIndex, to: cursorIndex)
            
            let (matches, descriptions) = debugger.commandInterpreter.handleCompletions(text, cursorPosition: cursorPosition, matchStart: 0)
            
            // The first string is the prefix common to all matches, so ignore it.
            let targets = zip(matches, descriptions).dropFirst().compactMap { match, description in
                let comps = match.split(separator: Regex {
                    ChoiceOf {
                        "."
                        "->"
                    }
                })
                let last = comps.last ?? ""
                
                var item = DebugAdapter.CompletionItem(label: String(last))
                item.detail = !description.isEmpty ? description : nil
                return item
            }
            
            replyHandler(.success(.init(targets: targets)))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func evaluate(_ request: DebugAdapter.EvaluateRequest, replyHandler: @escaping (Result<DebugAdapter.EvaluateRequest.Result, Error>) -> Void) {
        do {
            let frame = try request.frameId.flatMap { try self.frame(withID: $0) }
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
    
    private func executeCommand(_ expression: String, frame: Frame?) throws -> DebugAdapter.EvaluateRequest.Result {
        guard let debugger else {
            throw AdapterError.notDebugging
        }
        
        let context: ExecutionContext
        if let frame {
            context = ExecutionContext(from: frame)
        }
        else {
            guard let process = target?.process else {
                throw AdapterError.notDebugging
            }
            
            if let thread = process.selectedThread {
                context = ExecutionContext(from: thread)
            }
            else {
                context = ExecutionContext(from: process)
            }
        }
        
        let result = try debugger.commandInterpreter.handleCommand(expression, context: context, addToHistory: false)
        
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
    
    func disassemble(_ request: DebugAdapter.DisassembleRequest, replyHandler: @escaping (Result<DebugAdapter.DisassembleRequest.Result?, Error>) -> Void) {
        do {
            guard let target else {
                throw AdapterError.notDebugging
            }
            
            guard var addr = self.parseAddress(from: request.memoryReference) else {
                throw AdapterError.invalidParameter("Invalid memory reference “\(request.memoryReference)”.")
            }
            
            let offset = request.offset ?? 0
            if offset < 0 {
                addr -= UInt64(abs(offset))
            }
            else if offset > 0 {
                addr += UInt64(offset)
            }
            
            guard let address = Address(at: addr, in: target) else {
                throw AdapterError.invalidParameter("Memory reference not valid for the target binary.")
            }
            
            let instructionOffset = request.instructionOffset ?? 0
            let instructionCount = request.instructionCount
            let resolveSymbols = request.resolveSymbols ?? false
            
            guard let instructions = target.readInstructions(at: address, count: instructionOffset + instructionCount) else {
                throw AdapterError.invalidParameter("Could not read instructions for memory reference “\(request.memoryReference)”.")
            }
            
            let disassembledInstructions = instructions.dropFirst(instructionOffset).map { instruction in
                let instAddr = instruction.address
                let loadAddr = instAddr?.loadAddress(for: target)
                
                let addrStr = formatAddress(loadAddr ?? 0)
                
                var instStr = ""
                var symbolStr: String?
                
                if let symbol = instAddr?.symbol, symbol.startAddress == instAddr {
                    // Prepend the symbol name to the first line.
                    instStr += symbol.mangledName ?? symbol.name ?? "" + ": "
                    symbolStr = symbol.displayName
                }
                
                let mnemonic = instruction.mnemonic(for: target) ?? ""
                if mnemonic.count < 7 {
                    // Pad
                    instStr += String(repeating: " ", count: 7 - mnemonic.count) + mnemonic
                }
                else {
                    instStr += mnemonic
                }
                
                let operands = instruction.operands(for: target) ?? ""
                if mnemonic.count < 12 {
                    // Pad
                    instStr += String(repeating: " ", count: 12 - operands.count) + operands
                }
                else {
                    instStr += operands
                }
                
                if let comment = instruction.comment(for: target), !comment.isEmpty {
                    instStr += " ; \(comment)"
                }
                
                var disassembledInstruction = DebugAdapter.DisassembledInstruction(address: addrStr, instruction: instStr)
                
                if let data = instruction.data(for: target) {
                    disassembledInstruction.instructionBytes = data.reduce(into: "") { partialResult, byte in
                        partialResult.append(String(format: "%2.2x", byte))
                    }
                }
                
                if resolveSymbols {
                    disassembledInstruction.symbol = symbolStr
                }
                
                return disassembledInstruction
            }
            
            let result = DebugAdapter.DisassembleRequest.Result(instructions: disassembledInstructions)
            replyHandler(.success(result))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func readMemory(_ request: DebugAdapter.ReadMemoryRequest, replyHandler: @escaping (Result<DebugAdapter.ReadMemoryRequest.Result?, Error>) -> Void) {
        do {
            guard let target, let process = target.process else {
                throw AdapterError.notDebugging
            }
            
            guard var addr = self.parseAddress(from: request.memoryReference) else {
                throw AdapterError.invalidParameter("Invalid memory reference “\(request.memoryReference)”.")
            }
            
            let offset = request.offset ?? 0
            if offset < 0 {
                addr -= UInt64(abs(offset))
            }
            else if offset > 0 {
                addr += UInt64(offset)
            }
            
            let count = request.count
            
            let result = try withUnsafeTemporaryAllocation(byteCount: count, alignment: 8) { buffer in
                let read = try process.readMemory(buffer, at: addr)
                
                let addrStr = String(addr, radix: 16, uppercase: true)
                
                var result = DebugAdapter.ReadMemoryRequest.Result(address: addrStr)
                result.unreadableBytes = count - read
                result.data = Data(bytesNoCopy: buffer.baseAddress!, count: read, deallocator: .none).base64EncodedString()
                return result
            }
            replyHandler(.success(result))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func writeMemory(_ request: DebugAdapter.WriteMemoryRequest, replyHandler: @escaping (Result<DebugAdapter.WriteMemoryRequest.Result?, Error>) -> Void) {
        do {
            guard let target, let process = target.process else {
                throw AdapterError.notDebugging
            }
            
            guard var addr = self.parseAddress(from: request.memoryReference) else {
                throw AdapterError.invalidParameter("Invalid memory reference “\(request.memoryReference)”.")
            }
            
            let offset = request.offset ?? 0
            if offset < 0 {
                addr -= UInt64(abs(offset))
            }
            else if offset > 0 {
                addr += UInt64(offset)
            }
            
            guard let data = Data(base64Encoded: request.data) else {
                throw AdapterError.invalidParameter("Invalid base64-encoded data.")
            }
            
            let result = try data.withUnsafeBytes { bytes in
                let written = try process.writeMemory(bytes, at: addr)
                
                var result = DebugAdapter.WriteMemoryRequest.Result()
                result.bytesWritten = written
                return result
            }
            replyHandler(.success(result))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    // MARK: - Errors
    
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
                return reason
            }
        }
    }
    
    private func output(_ message: @autoclosure () -> String, category: DebugAdapter.OutputEvent.Category = .console) {
        connection.send(DebugAdapter.OutputEvent(output: message(), category: category))
    }
}
