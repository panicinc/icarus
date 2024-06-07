import Darwin
import Foundation
import SwiftLLDB

class Adapter: DebugAdapterServerRequestHandler {
    static let shared = Adapter()
    
    let connection = DebugAdapterConnection(transport: DebugAdapterFileHandleTransport())
    
    private(set) var isRunning = false
    
    func resume() {
        guard !isRunning else {
            return
        }
        
        signal(SIGINT) { sig in
            Adapter.shared.cancel(error: nil)
        }
        signal(SIGTERM) { sig in
            Adapter.shared.cancel(error: nil)
        }
        
        isRunning = true
        
        var configuration = DebugAdapterConnection.Configuration()
        
        configuration.messageQueue = .main
        
        configuration.loggingHandler = { message in
            
        }
        
        configuration.invalidationHandler = { [weak self] error in
            self?.cancel(error: error)
        }
        
        configuration.requestHandler = self
        
        connection.setConfiguration(configuration)
        
        connection.start()
        
        dispatchMain()
    }
    
    func cancel(error: Error?) {
        guard isRunning else {
            return
        }
        
        isRunning = false
        
        connection.stop()
        
        if error != nil {
            exit(EXIT_FAILURE)
        }
        else {
            exit(EXIT_SUCCESS)
        }
    }
    
    enum AdapterError: LocalizedError {
        case invalidArgument(String)
        
        var errorDescription: String? {
            switch self {
                case let .invalidArgument(reason):
                    return "Invalid argument: \(reason)"
            }
        }
    }
    
    private func logOutput(_ message: String, category: DebugAdapter.OutputEvent.Category) {
        connection.send(DebugAdapter.OutputEvent(output: message, category: category))
    }
    
    // MARK: - Configuration
    
    private var debugger: Debugger?
    private var listener: Listener?
    
    private struct ClientOptions {
        var clientID: String?
        var clientName: String?
        var adapterID: String?
        
        var linesStartAt1 = true
        var columnsStartAt1 = true
    }
    private var clientOptions = ClientOptions()
    
    private enum ExceptionBreakpointFilter: String, Hashable, CaseIterable {
        case swift
        case cppThrow = "cpp_throw"
        case cppCatch = "cpp_catch"
        case objcThrow = "objc_throw"
        case objcCatch = "objc_catch"
        
        var name: String {
            switch self {
            case .swift:
                return "Swift"
            case .cppThrow:
                return "C++: on Throw"
            case .cppCatch:
                return "C++: on Catch"
            case .objcThrow:
                return "Objective-C: on Throw"
            case .objcCatch:
                return "Objective-C: on Catch"
            }
        }
    }
    
    func initialize(_ request: DebugAdapter.InitializeRequest, replyHandler: @escaping (Result<DebugAdapter.InitializeRequest.Result?, Error>) -> ()) {
        // Initialize LLDB
        do {
            try Debugger.initialize()
        }
        catch {
            replyHandler(.failure(error))
            return
        }
        
        // Debugger
        let debugger = Debugger()
        self.debugger = debugger
        
        // Event listener
        let listener = Listener(name: "com.panic.lldb-adapter.listener") { [weak self] event in
            DispatchQueue.main.async { [weak self] in
                self?.handleDebuggerEvent(event)
            }
        }
        listener.startListening(in: debugger, eventClass: SwiftLLDB.Target.broadcasterClassName, mask: UInt32.max)
        listener.startListening(in: debugger, eventClass: SwiftLLDB.Process.broadcasterClassName, mask: UInt32.max)
        listener.startListening(in: debugger, eventClass: SwiftLLDB.Thread.broadcasterClassName, mask: UInt32.max)
        self.listener = listener
        listener.resume()
        
        // Client options
        var options = ClientOptions()
        
        options.clientID = request.clientID
        options.clientName = request.clientName
        options.adapterID = request.adapterID
        
        options.linesStartAt1 = request.linesStartAt1 ?? true
        options.columnsStartAt1 = request.columnsStartAt1 ?? true
        
        clientOptions = options
        
        // Capabilities
        var capabilities = DebugAdapter.Capabilities()
        
        capabilities.supportsConfigurationDoneRequest = true
        capabilities.supportsFunctionBreakpoints = true
        capabilities.supportsConditionalBreakpoints = true
        capabilities.supportsSetVariable = true
        capabilities.supportTerminateDebuggee = true
        capabilities.supportsExceptionInfoRequest = true
        capabilities.supportsEvaluateForHovers = true
        capabilities.supportsReadMemoryRequest = true
        capabilities.supportsCompletionsRequest = true
        capabilities.supportsWriteMemoryRequest = true
        
        capabilities.exceptionBreakpointFilters = ExceptionBreakpointFilter.allCases.map { .init(filter: $0.rawValue, label: $0.name) }
        
        replyHandler(.success(capabilities))
    }
    
    private enum DebugStartRequest {
        case launch(DebugAdapter.LaunchRequest<LaunchParameters>, (Result<(), Error>) -> ())
        case attach(DebugAdapter.AttachRequest<AttachParameters>, (Result<(), Error>) -> ())
    }
    private var debugStartRequest: DebugStartRequest?
    
    struct PathMapping: Codable {
        var localRoot: String
        var remoteRoot: String
    }
    
    private struct Configuration {
        enum Start {
            case launch(Target.LaunchOptions)
            case attach(Target.AttachOptions)
        }
        var start: Start?
        
        var isLocal = true
        var terminateOnDisconnect = false
        var pathMappings: [PathMapping] = []
    }
    private var configuration = Configuration()
    
    private var target: Target?
    
    private func localPath(forRemotePath path: String) -> String {
        for mapping in configuration.pathMappings {
            if path.hasPrefix(mapping.remoteRoot) {
                let substring = path[path.index(path.startIndex, offsetBy: mapping.remoteRoot.count) ..< path.endIndex]
                return mapping.localRoot.appending(substring)
            }
        }
        return path
    }
    
    private func remotePath(forLocalPath path: String) -> String {
        for mapping in configuration.pathMappings {
            if path.hasPrefix(mapping.localRoot) {
                let substring = path[path.index(path.startIndex, offsetBy: mapping.localRoot.count) ..< path.endIndex]
                return mapping.remoteRoot.appending(substring)
            }
        }
        return path
    }
    
    struct LaunchParameters: Codable {
        var program: String
        var args: [String]?
        var env: [String: String]?
        var cwd: String?
        var arch: String?
        var runInRosetta: Bool?
        var stopAtEntry: Bool?
        
        var port: UInt16?
        var host: String?
        var platform: String?
        var pathMappings: [PathMapping]?
    }
    
    func launch(_ request: DebugAdapter.LaunchRequest<LaunchParameters>, replyHandler: @escaping (Result<(), Error>) -> ()) {
        do {
            guard let debugger else {
                throw AdapterError.invalidArgument("No `initialize` request was sent before `launch`.")
            }
            
            let parameters = request.parameters
            
            let launchPath = parameters.program
            
            var options = Target.LaunchOptions()
            
            options.arguments = parameters.args
            options.environment = parameters.env
            options.workingDirectory = parameters.cwd
            
            var configuration = Configuration()
            
            var architecture: Architecture?
            if let archString = parameters.arch {
                architecture = Architecture(rawValue: archString)
            }
            else if let runInRosetta = parameters.runInRosetta, runInRosetta {
                architecture = .x86_64
            }
            
            if let stopAtEntry = parameters.stopAtEntry, stopAtEntry {
                options.stopAtEntry = stopAtEntry
            }
            
            let target: Target
            if let port = parameters.port {
                // Remote Debugging Port
                let host = parameters.host ?? "localhost"
                let platformName = parameters.platform ?? "remote-linux"
                
                let platform = Platform(name: platformName)
                
                logOutput("Connecting to LLDB remote host \"\(host):\(port)\".", category: .console)
                
                let options = Platform.ConnectOptions(url: "connect://\(host):\(port)")
                try platform.connect(with: options)
                
                debugger.setSelectedPlatform(platform)
                
                target = try debugger.createTarget(path: launchPath, triple: nil, platform: nil)
                
                configuration.isLocal = false
            }
            else {
                target = try debugger.createTarget(path: launchPath, architecture: architecture ?? .system)
            }
            
            self.target = target
            
            configuration.start = .launch(options)
            configuration.terminateOnDisconnect = true
            
            configuration.pathMappings = (parameters.pathMappings ?? []).map { mapping in
                var localRoot = mapping.localRoot
                if !localRoot.hasSuffix("/") {
                    localRoot = localRoot.appending("/")
                }
                
                var remoteRoot = mapping.remoteRoot
                if !remoteRoot.hasSuffix("/") {
                    remoteRoot = remoteRoot.appending("/")
                }
                
                return PathMapping(localRoot: localRoot, remoteRoot: remoteRoot)
            }
            
            self.configuration = configuration
            
            debugStartRequest = .launch(request, replyHandler)
            
            connection.send(DebugAdapter.InitializedEvent())
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    struct AttachParameters: Codable {
        var program: String?
        var pid: UInt64?
        var wait: Bool?
        
        var port: UInt16?
        var host: String?
        var platform: String?
        var pathMappings: [PathMapping]?
    }
    
    func attach(_ request: DebugAdapter.AttachRequest<AttachParameters>, replyHandler: @escaping (Result<(), Error>) -> ()) {
        do {
            guard let debugger else {
                throw AdapterError.invalidArgument("No `initialize` request was sent before `attach`.")
            }
            
            let parameters = request.parameters
            
            var options: Target.AttachOptions
            
            var configuration = Configuration()
            
            let target: Target
            if let port = parameters.port, let attachPath = parameters.program {
                // Remote Debugging Port
                let host = parameters.host ?? "localhost"
                let platformName = parameters.platform ?? "remote-linux"
                
                let platform = Platform(name: platformName)
                
                logOutput("Connecting to LLDB remote host \"\(host):\(port)\".", category: .console)
                
                let connectOptions = Platform.ConnectOptions(url: "connect://\(host):\(port)")
                try platform.connect(with: connectOptions)
                
                debugger.setSelectedPlatform(platform)
                
                options = .init(executablePath: attachPath)
                target = try debugger.createTarget(path: attachPath, triple: nil, platform: nil)
                
                configuration.isLocal = false
            }
            else if let pid = parameters.pid,
                    let t = debugger.findTarget(processIdentifier: pid) {
                // Process Identifier
                options = .init(processIdentifier: pid)
                target = t
            }
            else if let attachPath = parameters.program {
                // Process Path
                options = .init(executablePath: attachPath)
                target = try debugger.createTarget(path: attachPath, architecture: .system)
            }
            else {
                replyHandler(.failure(AdapterError.invalidArgument("No pid or process name specified for `attach` request.")))
                return
            }
            
            options.waitForLaunch = parameters.wait ?? false
            
            self.target = target
            
            configuration.start = .attach(options)
            
            configuration.pathMappings = (parameters.pathMappings ?? []).map { mapping in
                var localRoot = mapping.localRoot
                if !localRoot.hasSuffix("/") {
                    localRoot = localRoot.appending("/")
                }
                
                var remoteRoot = mapping.remoteRoot
                if !remoteRoot.hasSuffix("/") {
                    remoteRoot = remoteRoot.appending("/")
                }
                
                return PathMapping(localRoot: localRoot, remoteRoot: remoteRoot)
            }
            
            self.configuration = configuration
            
            debugStartRequest = .attach(request, replyHandler)
            
            connection.send(DebugAdapter.InitializedEvent())
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func configurationDone(_ request: DebugAdapter.ConfigurationDoneRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        replyHandler(.success(()))
        startSession()
    }
    
    private var attachWaitProcess: SwiftLLDB.Process?
    
    private func startSession() {
        do {
            guard let start = configuration.start, let target else {
                throw AdapterError.invalidArgument("No `launch` or `attach` request was sent before `configurationDone`.")
            }
            
            switch start {
                case let .launch(options):
                    let process = try target.launch(with: options)
                    
                    sendProcessEvent(process, startMethod: .launch)
                    
                    if options.stopAtEntry {
                        notifyProcessStopped()
                    }
                    
                case let .attach(options):
                    let process = try target.attach(with: options)
                    
                    if options.waitForLaunch {
                        attachWaitProcess = process
                    }
                    else {
                        sendProcessEvent(process, startMethod: .attach)
                        
                        if options.stopAtEntry {
                            notifyProcessStopped()
                        }
                    }
            }
            
            // Reply to launch or attach request
            if let request = debugStartRequest {
                switch request {
                case .launch(_, let launchHandler):
                    launchHandler(.success(()))
                case .attach(_, let launchHandler):
                    launchHandler(.success(()))
                }
                debugStartRequest = nil
            }
        }
        catch {
            // Reply to launch or attach request
            if let request = debugStartRequest {
                switch request {
                case .launch(_, let launchHandler):
                    launchHandler(.failure(error))
                case .attach(_, let launchHandler):
                    launchHandler(.failure(error))
                }
                debugStartRequest = nil
            }
        }
    }
    
    private func sendProcessEvent(_ process: SwiftLLDB.Process, startMethod: DebugAdapter.ProcessEvent.StartMethod) {
        // Process event
        let processIdentifier = process.processIdentifier
        
        let processInfo = process.info
        let name = processInfo.name
        
        var event = DebugAdapter.ProcessEvent(name: name)
        event.startMethod = startMethod
        if configuration.isLocal {
            event.isLocalProcess = true
            event.systemProcessId = Int(processIdentifier)
        }
        connection.send(event)
    }
    
    private func handleDebuggerEvent(_ event: Event) {
        if let breakpointEvent = BreakpointEvent(event) {
            handleBreakpointEvent(breakpointEvent)
        }
        else if let processEvent = ProcessEvent(event) {
            handleProcessEvent(processEvent)
        }
        else if let targetEvent = TargetEvent(event) {
            handleTargetEvent(targetEvent)
        }
        else if let threadEvent = ThreadEvent(event) {
            handleThreadEvent(threadEvent)
        }
    }
    
    // MARK: - Breakpoints
    
    private(set) var sourceBreakpoints: [String: [Int: DebugAdapter.SourceBreakpoint]] = [:]
    
    private func handleBreakpointEvent(_ event: BreakpointEvent) {
        let eventType = event.eventType
        if eventType.contains(.added) {
            
        }
        else if eventType.contains(.locationsAdded) || eventType.contains(.locationsResolved) {
            
        }
        else if eventType.contains(.removed) {
            
        }
    }
    
    func setBreakpoints(_ request: DebugAdapter.SetBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetBreakpointsRequest.Result, Error>) -> ()) {
        let source = request.source
        
        guard let path = source.path else {
            replyHandler(.failure(AdapterError.invalidArgument("Breakpoint source path is missing.")))
            return
        }
        
        guard let target else {
            replyHandler(.failure(AdapterError.invalidArgument("Not debugging a target.")))
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
            
            var bp: Breakpoint
            if let matchingBP, let breakpoint = target.findBreakpoint(withID: matchingBP.key) {
                bp = breakpoint
                previousBreakpoints[matchingBP.key] = nil
            }
            else {
                let remotePath = remotePath(forLocalPath: path)
                bp = target.createBreakpoint(path: remotePath, line: line, column: column, offset: nil, moveToNearestCode: true)
            }
            
            if let condition = sourceBreakpoint.condition {
                bp.condition = condition
            }
            
            let id = bp.id
            
            var breakpoint = DebugAdapter.Breakpoint()
            breakpoint.id = id
            
            breakpoint.line = line
            breakpoint.column = column
            breakpoint.source = source
            
            breakpoints.append(breakpoint)
            newBreakpoints[id] = sourceBreakpoint
        }
        
        // Update active session
        for (id, _) in previousBreakpoints {
            _ = target.removeBreakpoint(withID: id)
        }
        
        sourceBreakpoints[path] = newBreakpoints.count > 0 ? newBreakpoints : nil
        
        replyHandler(.success(.init(breakpoints: breakpoints)))
    }
    
    private(set) var functionBreakpoints: [Int: DebugAdapter.FunctionBreakpoint] = [:]
    
    func setFunctionBreakpoints(_ request: DebugAdapter.SetFunctionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetFunctionBreakpointsRequest.Result?, Error>) -> ()) {
        guard let target else {
            replyHandler(.failure(AdapterError.invalidArgument("Not debugging a target.")))
            return
        }
        
        // Create new breakpoints
        var breakpoints: [DebugAdapter.Breakpoint] = []
        var newFunctionBreakpoints: [Int: DebugAdapter.FunctionBreakpoint] = [:]
        
        var previousBreakpoints = functionBreakpoints
        
        for functionBreakpoint in request.breakpoints {
            let name = functionBreakpoint.name
            
            let matchingBP = previousBreakpoints.first(where: { $0.value.name == name })
            
            var bp: Breakpoint
            if let matchingBP, let breakpoint = target.findBreakpoint(withID: matchingBP.key) {
                bp = breakpoint
                previousBreakpoints[matchingBP.key] = nil
            }
            else {
                bp = target.createBreakpoint(name: name)
            }
            
            if let condition = functionBreakpoint.condition {
                bp.condition = condition
            }
            
            let id = bp.id
            
            var breakpoint = DebugAdapter.Breakpoint()
            breakpoint.id = id
            breakpoint.verified = false
            
            breakpoints.append(breakpoint)
            newFunctionBreakpoints[id] = functionBreakpoint
        }
        
        // Update active session
        for (id, _) in previousBreakpoints {
            _ = target.removeBreakpoint(withID: id)
        }
        
        functionBreakpoints = newFunctionBreakpoints
        
        replyHandler(.success(.init(breakpoints: breakpoints)))
    }
    
    private(set) var exceptionFilters: [Int: String] = [:]
    
    func setExceptionBreakpoints(_ request: DebugAdapter.SetExceptionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetExceptionBreakpointsRequest.Result?, Error>) -> ()) {
        guard let target else {
            replyHandler(.failure(AdapterError.invalidArgument("Not debugging a target.")))
            return
        }
        
        var newExceptionFilters: [Int: String] = [:]
        var breakpoints: [DebugAdapter.Breakpoint] = []
        
        var previousFilters = exceptionFilters
        
        if let filters = request.filters {
            for filterName in filters {
                let matchingBP = previousFilters.first(where: { $0.value == filterName })
                
                let bp: Breakpoint
                if let matchingBP, let breakpoint = target.findBreakpoint(withID: matchingBP.key) {
                    bp = breakpoint
                    previousFilters[matchingBP.key] = nil
                }
                else if let filter = ExceptionBreakpointFilter(rawValue: filterName) {
                    switch filter {
                    case .swift:
                        bp = target.createBreakpoint(forExceptionIn: .swift, onCatch: false, onThrow: true)
                    case .cppThrow:
                        bp = target.createBreakpoint(forExceptionIn: .cxx, onCatch: false, onThrow: true)
                    case .cppCatch:
                        bp = target.createBreakpoint(forExceptionIn: .cxx, onCatch: true, onThrow: false)
                    case .objcThrow:
                        bp = target.createBreakpoint(forExceptionIn: .objectiveC, onCatch: false, onThrow: true)
                    case .objcCatch:
                        bp = target.createBreakpoint(forExceptionIn: .objectiveC, onCatch: true, onThrow: false)
                    }
                }
                else {
                    replyHandler(.failure(AdapterError.invalidArgument("Unsupported exception filter: \(filterName).")))
                    return
                }
                
                let id = bp.id
                
                var breakpoint = DebugAdapter.Breakpoint()
                breakpoint.id = id
                breakpoint.verified = false
                
                breakpoints.append(breakpoint)
                newExceptionFilters[id] = filterName
            }
        }
        
        exceptionFilters = newExceptionFilters
        
        for (id, _) in previousFilters {
            _ = target.removeBreakpoint(withID: id)
        }
        
        replyHandler(.success(.init(breakpoints: breakpoints)))
    }
    
    // MARK: - Execution
    
    private func handleProcessEvent(_ event: ProcessEvent) {
        let process = event.process
        let flags = event.flags
        
        if flags.contains(.stateChanged) {
            let state = event.processState
            switch state {
            case .running, .stepping:
                notifyProcessRunning()
            case .stopped:
                if let process = attachWaitProcess {
                    // Attached
                    sendProcessEvent(process, startMethod: .attach)
                    
                    switch configuration.start {
                    case let .attach(options):
                        if options.stopAtEntry {
                            notifyProcessStopped()
                        }
                    default:
                        break
                    }
                    
                    attachWaitProcess = nil
                }
                
                if !event.isRestarted {
                    notifyProcessStopped()
                }
            case .crashed, .suspended:
                notifyProcessStopped()
            case .exited:
                let process = event.process
                let exitCode = Int(process.exitStatus)
                logOutput("Process exited with code \(exitCode).", category: .console)
                connection.send(DebugAdapter.ExitedEvent(exitCode: exitCode))
                connection.send(DebugAdapter.TerminatedEvent())
            case .detached:
                logOutput("Detached from debuggee.", category: .console)
                connection.send(DebugAdapter.TerminatedEvent())
            default:
                break
            }
        }
        
        if flags.contains(.standardOut) {
            while true {
                let chunk = process.readFromStandardOut(count: 1024)
                if chunk.count == 0 {
                    break
                }
                
                guard let string = String(data: chunk, encoding: .ascii) else {
                    break
                }
                
                logOutput(string, category: .standardOut)
            }
        }
        
        if flags.contains(.standardError) {
            while true {
                let chunk = process.readFromStandardError(count: 1024)
                if chunk.count == 0 {
                    break
                }
                
                guard let string = String(data: chunk, encoding: .ascii) else {
                    break
                }
                
                logOutput(string, category: .standardError)
            }
        }
    }
    
    private func notifyProcessRunning() {
        var event = DebugAdapter.ContinuedEvent(threadId: 0)
        event.allThreadsContinued = true
        connection.send(event)
    }
    
    private func notifyProcessStopped() {
        guard let process = target?.process else {
            return
        }
        
        let selectedThread = process.selectedThread
        var stoppedThread: SwiftLLDB.Thread?
        if let selectedThread {
            let stopReason = selectedThread.stopReason
            if stopReason != .invalid && stopReason != .none {
                stoppedThread = selectedThread
            }
        }
        
        if stoppedThread == nil {
            for thread in process.threads {
                let stopReason = thread.stopReason
                if stopReason != .invalid && stopReason != .none {
                    process.setSelectedThread(thread)
                    stoppedThread = thread
                    break
                }
            }
        }
        
        let reason: DebugAdapter.StoppedEvent.Reason
        var hitBreakpointIDs: [Int] = []
        
        if let stoppedThread {
            switch stoppedThread.stopReason {
                case .breakpoint:
                    reason = .breakpoint
                    
                    let reasonCount = stoppedThread.stopReasonDataCount
                    if reasonCount >= 2 {
                        // Breakpoint reason data consists of pairs of [breakpointID, breakpointLocationID].
                        for i in 0 ..< (reasonCount / 2) {
                            let breakpointID = stoppedThread.stopReasonData(at: i)
                            hitBreakpointIDs.append(Int(breakpointID))
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
        event.threadId = Int(truncatingIfNeeded: stoppedThread?.id ?? 0)
        if hitBreakpointIDs.count > 0 {
            event.hitBreakpointIds = hitBreakpointIDs
        }
        
        connection.send(event)
    }
    
    private func willContinue() {
        variables.removeAll()
    }
    
    private func handleTargetEvent(_ event: TargetEvent) {
        
    }
    
    private func handleThreadEvent(_ event: ThreadEvent) {
        
    }
    
    func disconnect(_ request: DebugAdapter.DisconnectRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        if let process = target?.process {
            // Terminate debuggee if needed
            let shouldTerminate = request.terminateDebuggee ?? configuration.terminateOnDisconnect
            do {
                if shouldTerminate {
                    try process.kill()
                }
                else {
                    try process.detach()
                }
            }
            catch {
                
            }
        }
        self.target = nil
        
        // Stop any waiting for an attach
        if let attachWaitProcess {
            do {
                try attachWaitProcess.stop()
            }
            catch {
                
            }
            self.attachWaitProcess = nil
        }
        
        // Clear all breakpoint callbacks
        Breakpoint.clearAllCallbacks()
        
        configuration.start = nil
        replyHandler(.success(()))
    }
    
    func pause(_ request: DebugAdapter.PauseRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        do {
            guard let target, let process = target.process else {
                throw AdapterError.invalidArgument("No debuggee is running.")
            }
            
            try process.stop()
            replyHandler(.success(()))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func `continue`(_ request: DebugAdapter.ContinueRequest, replyHandler: @escaping (Result<DebugAdapter.ContinueRequest.Result, Error>) -> ()) {
        do {
            guard let target, let process = target.process else {
                throw AdapterError.invalidArgument("No debuggee is running.")
            }
            
            willContinue()
            
            try process.resume()
            
            var result = DebugAdapter.ContinueRequest.Result()
            result.allThreadsContinued = true
            replyHandler(.success(result))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func next(_ request: DebugAdapter.NextRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        do {
            guard let target, let process = target.process else {
                throw AdapterError.invalidArgument("No debuggee is running.")
            }
            
            let threadID = request.threadId
            guard let thread = process.thread(withID: threadID) else {
                throw AdapterError.invalidArgument("Unknown thread \(threadID).")
            }
            
            willContinue()
            
            try thread.stepOver()
            
            replyHandler(.success(()))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func stepIn(_ request: DebugAdapter.StepInRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        do {
            guard let target, let process = target.process else {
                throw AdapterError.invalidArgument("No debuggee is running.")
            }
            
            let threadID = request.threadId
            guard let thread = process.thread(withID: threadID) else {
                throw AdapterError.invalidArgument("Unknown thread \(threadID).")
            }
            
            willContinue()
            
            try thread.stepInto()
            
            replyHandler(.success(()))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func stepOut(_ request: DebugAdapter.StepOutRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        do {
            guard let target, let process = target.process else {
                throw AdapterError.invalidArgument("No debuggee is running.")
            }
            
            let threadID = request.threadId
            guard let thread = process.thread(withID: threadID) else {
                throw AdapterError.invalidArgument("Unknown thread \(threadID).")
            }
            
            willContinue()
            
            try thread.stepOut()
            
            replyHandler(.success(()))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    // MARK: - Threads
    
    enum VariableContainer {
        case stackFrame(Frame)
        case locals(Frame)
        case statics(Frame)
        case globals(Frame)
        case registers(Frame)
        case value(Value)
    }
    var variables = ReferenceTree<Int, VariableContainer>(startingAt: 1000)
    
    func threads(_ request: DebugAdapter.ThreadsRequest, replyHandler: @escaping (Result<DebugAdapter.ThreadsRequest.Result, Error>) -> ()) {
        guard let target, let process = target.process else {
            replyHandler(.failure(AdapterError.invalidArgument("No debuggee is running.")))
            return
        }
        
        let threads = process.threads.map { thread in
            return DebugAdapter.Thread(id: thread.id, name: thread.name ?? "Thread \(thread.indexID)")
        }
        
        replyHandler(.success(.init(threads: threads)))
    }
    
    func stackTrace(_ request: DebugAdapter.StackTraceRequest, replyHandler: @escaping (Result<DebugAdapter.StackTraceRequest.Result, Error>) -> ()) {
        guard let target, let process = target.process else {
            replyHandler(.failure(AdapterError.invalidArgument("No debuggee is running.")))
            return
        }
        
        let threadID = request.threadId
        guard let thread = process.thread(withID: threadID) else {
            replyHandler(.failure(AdapterError.invalidArgument("Invalid thread ID \(threadID).")))
            return
        }
        
        let frames = thread.frames.enumerated().map { (idx, frame) in
            let key = "[\(thread.indexID), \(idx)]"
            let ref = variables.insert(parent: nil, key: key, value: .stackFrame(frame))
            
            var debugFrame = DebugAdapter.StackFrame(id: ref)
            
            debugFrame.name = frame.function?.displayName ?? "\(String(format: "%02X", frame.programCounter))"
            
            let lineEntry = frame.lineEntry
            let fileSpec = lineEntry.fileSpec
            if let filename = fileSpec.filename,
               let path = fileSpec.path {
                let localPath = localPath(forRemotePath: path)
                
                var source = DebugAdapter.Source()
                source.name = filename
                source.path = localPath
                debugFrame.source = source
                
                debugFrame.line = Int(lineEntry.line)
                debugFrame.column = Int(lineEntry.column)
            }
            else {
                debugFrame.presentationHint = .subtle
            }
            
            return debugFrame
        }
        
        replyHandler(.success(.init(stackFrames: frames)))
    }
    
    func scopes(_ request: DebugAdapter.ScopesRequest, replyHandler: @escaping (Result<DebugAdapter.ScopesRequest.Result, Error>) -> ()) {
        let frameID = request.frameId
        
        switch variables[frameID] {
            case let .stackFrame(frame):
                let localsRef = variables.insert(parent: frameID, key: "._locals", value: .locals(frame))
                var localsScope = DebugAdapter.Scope(name: "Local", variablesReference: localsRef)
                localsScope.presentationHint = .locals
                
                let staticsRef = variables.insert(parent: frameID, key: "._statics", value: .statics(frame))
                let staticsScope = DebugAdapter.Scope(name: "Static", variablesReference: staticsRef)
                
                let globalsRef = variables.insert(parent: frameID, key: "._globals", value: .globals(frame))
                var globalsScope = DebugAdapter.Scope(name: "Global", variablesReference: globalsRef)
                globalsScope.presentationHint = .globals
                
                let registersRef = variables.insert(parent: frameID, key: "._registers", value: .registers(frame))
                var registersScope = DebugAdapter.Scope(name: "Registers", variablesReference: registersRef)
                registersScope.presentationHint = .registers
                
                let scopes = [localsScope, staticsScope, globalsScope, registersScope]
                
                replyHandler(.success(.init(scopes: scopes)))
            
            default:
                replyHandler(.failure(AdapterError.invalidArgument("Invalid stack frame ID \(frameID).")))
                return
        }
    }
    
    func variables(_ request: DebugAdapter.VariablesRequest, replyHandler: @escaping (Result<DebugAdapter.VariablesRequest.Result, Error>) -> ()) {
        let ref = request.variablesReference
        
        if let container = variables[ref] {
            switch container {
                case let .locals(frame):
                    let values = frame.variables(for: [.arguments, .locals], inScopeOnly: true)
                    let variables = self.variables(for: values, containerRef: ref, uniquing: true)
                    replyHandler(.success(.init(variables: variables)))
                    
                case let .statics(frame):
                    let values = frame.variables(for: [.statics], inScopeOnly: true)
                    let variables = self.variables(for: values, types: [.static], containerRef: ref, uniquing: false)
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
            replyHandler(.failure(AdapterError.invalidArgument("Invalid variables reference: \(ref).")))
        }
    }
    
    private func variables<S>(for values: S, types: Set<Value.ValueType>? = nil, containerRef: Int, uniquing: Bool) -> [DebugAdapter.Variable] where S: Sequence, S.Element == Value {
        var variables: [DebugAdapter.Variable] = []
        var variablesIndexesByName: [String: Int] = [:]
        
        for value in values {
            if let types, !types.contains(value.valueType) {
                continue
            }
            
            guard let name = value.name else {
                continue
            }
            
            let summary = displayString(forValue: value)
            
            var variable = DebugAdapter.Variable(name: name, value: summary)
            
            variable.type = value.displayTypeName
            variable.variablesReference = variableReference(for: value, key: name, parent: containerRef)
            
            if uniquing {
                if let idx = variablesIndexesByName[name] {
                    variables[idx] = variable
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
        if value.childCount > 0 && !value.isSynthetic {
            return variables.insert(parent: parent, key: key, value: .value(value))
        }
        else {
            return nil
        }
    }
    
    private func displayString(forValue value: Value) -> String {
        return value.summary ?? value.value ?? "<unavailable>"
    }
    
    func exceptionInfo(_ request: DebugAdapter.ExceptionInfoRequest, replyHandler: @escaping (Result<DebugAdapter.ExceptionInfoRequest.Result, Error>) -> ()) {
        replyHandler(.failure(AdapterError.invalidArgument("Not yet implemented.")))
    }
    
    func completions(_ request: DebugAdapter.CompletionsRequest, replyHandler: @escaping (Result<DebugAdapter.CompletionsRequest.Result, Error>) -> ()) {
        do {
            guard let debugger else {
                throw AdapterError.invalidArgument("No debuggee is running.")
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
    
    func evaluate(_ request: DebugAdapter.EvaluateRequest, replyHandler: @escaping (Result<DebugAdapter.EvaluateRequest.Result, Error>) -> ()) {
        do {
            var frame: Frame?
            if let frameID = request.frameId {
                let container = variables[frameID]
                switch container {
                case let .stackFrame(f):
                    frame = f
                default:
                    break
                }
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
            guard let target else {
                throw AdapterError.invalidArgument("No debuggee is running.")
            }
            
            if let process = target.process, let thread = process.selectedThread {
                return ExecutionContext(from: thread)
            }
            else {
                return ExecutionContext(from: target)
            }
        }
    }
    
    private func executeCommand(_ expression: String, frame: Frame?) throws -> DebugAdapter.EvaluateRequest.Result {
        guard let debugger else {
            throw AdapterError.invalidArgument("No debuggee is running.")
        }
        
        let interpreter = debugger.commandInterpreter
        let context = try executionContext(for: frame)
        let result = try interpreter.handleCommand(expression, context: context, addToHistory: false)
        
        return .init(result: result.output ?? "")
    }
    
    private func evaluateExpression(_ expression: String, frame: Frame?) throws -> DebugAdapter.EvaluateRequest.Result {
        guard let target else {
            throw AdapterError.invalidArgument("No debuggee is running.")
        }
        
        let result: Value
        if let frame {
            result = try frame.evaluate(expression: expression)
        }
        else {
            result = try target.evaluate(expression: expression)
        }
        
        let summary = displayString(forValue: result)
        
        var requestResult = DebugAdapter.EvaluateRequest.Result(result: summary)
        requestResult.type = result.displayTypeName
        requestResult.variablesReference = variableReference(for: result, key: expression, parent: nil) ?? 0
        
        return requestResult
    }
    
    func setVariable(_ request: DebugAdapter.SetVariableRequest, replyHandler: @escaping (Result<DebugAdapter.SetVariableRequest.Result, Error>) -> ()) {
        do {
            let name = request.name
            
            let ref = request.variablesReference
            let container = variables[ref]
            
            let child: Value?
            switch container {
            case let .value(value):
                child = value.childMember(withName: name)
            case let .locals(frame), let .globals(frame), let .statics(frame):
                child = frame.findVariable(withName: name)
            default:
                child = nil
            }
            
            if let child, let childName = child.name {
                let value = request.value
                try child.setValue(value)
                
                let summary = displayString(forValue: child)
                
                var result = DebugAdapter.SetVariableRequest.Result(value: summary)
                result.type = child.displayTypeName
                result.variablesReference = variableReference(for: child, key: childName, parent: ref)
                
                replyHandler(.success(result))
            }
            else {
                throw AdapterError.invalidArgument("Unable to set variable value \"\(name)\".")
            }
        }
        catch {
            replyHandler(.failure(error))
        }
    }
}
