import Cocoa
import Dispatch
import LLDBObjC

class Adapter: DebugAdapterServerRequestHandler {
    static let shared = Adapter()
    
    let connection = DebugAdapterConnection(transport: DebugAdapterFileHandleTransport())
    let queue = DispatchQueue(label: "com.panic.lldb-adapter")
    
    private(set) var isRunning = false
    
    func resume() {
        guard !isRunning else {
            return
        }
        
        isRunning = true
        
        var configuration = DebugAdapterConnection.Configuration()
        
        configuration.messageQueue = queue
        
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
            exit(1)
        }
        else {
            exit(0)
        }
    }
    
    enum AdapterError: LocalizedError {
        case invalidArguments(reason: String)
        
        var errorDescription: String? {
            switch self {
                case .invalidArguments(reason: let reason):
                    return "Invalid arguments: \(reason)"
            }
        }
    }
    
    // MARK: - Configuration
    
    private var debugger: LLDBDebugger?
    private var listener: LLDBListener?
    
    private struct ClientOptions {
        var clientID: String?
        var clientName: String?
        var adapterID: String?
        
        var linesStartAt1 = true
        var columnsStartAt1 = true
    }
    private var clientOptions = ClientOptions()
    
    func initialize(_ request: DebugAdapter.InitializeRequest, replyHandler: @escaping (Result<DebugAdapter.InitializeRequest.Result?, Error>) -> ()) {
        // Initialize LLDB
        do {
            try LLDBDebugger.initializeWithError()
        }
        catch {
            replyHandler(.failure(error))
            return
        }
        
        // Debugger
        let debugger = LLDBDebugger()
        self.debugger = debugger
        
        // Event listener
        let listener = LLDBListener(name: "com.panic.lldb-adapter.listener", queue: queue)
        listener.eventHandler = { [weak self] event in
            self?.handleDebuggerEvent(event)
        }
        listener.startListening(in: debugger, eventClass: LLDBTarget.broadcasterClassName, mask: UInt32.max)
        listener.startListening(in: debugger, eventClass: LLDBProcess.broadcasterClassName, mask: UInt32.max)
        // listener.startListening(in: debugger, eventClass: LLDBThread.broadcasterClassName, mask: UInt32.max)
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
        capabilities.supportsConditionalBreakpoints = true
        capabilities.supportsEvaluateForHovers = true
        capabilities.supportsCompletionsRequest = true
        capabilities.supportTerminateDebuggee = true
        capabilities.supportsExceptionInfoRequest = true
        
        let swiftRuntimeFilter = DebugAdapter.ExceptionBreakpointFilter(filter: "swiftErrors", label: "Swift Errors")
        let cppExceptionsFilter = DebugAdapter.ExceptionBreakpointFilter(filter: "cppExceptions", label: "C++ Exceptions")
        let objcExceptionsFilter = DebugAdapter.ExceptionBreakpointFilter(filter: "objcExceptions", label: "Objective-C Exceptions")
        
        capabilities.exceptionBreakpointFilters = [swiftRuntimeFilter, cppExceptionsFilter, objcExceptionsFilter]
        
        replyHandler(.success(capabilities))
    }
    
    private func handleDebuggerEvent(_ event: LLDBEvent) {
        if let breakpointEvent = event.toBreakpointEvent() {
            
        }
        else if let targetEvent = event.toTargetEvent() {
            
        }
        else {
            
        }
    }
    
    private enum DebugStartRequest {
        case launch(DebugAdapter.LaunchRequest, (Result<(), Error>) -> ())
        case attach(DebugAdapter.AttachRequest, (Result<(), Error>) -> ())
    }
    private var debugStartRequest: DebugStartRequest?
    
    enum Architecture: String {
        case systemDefault = "systemArch"
        case systemDefault64 = "systemArch64"
        case systemDefault32 = "systemArch32"
        case appleSilicon = "arm64"
        case x86_64
        case x86
    }
    
    enum Configuration {
        struct LaunchOptions {
            var url: URL
            var arguments: [String]?
            var environment: [String: String]?
            var currentDirectoryURL: URL?
            var architecture: Architecture?
        }
        case launch(LaunchOptions)
        
        struct AttachToPIDOptions {
            var pid: pid_t
            var waitForProcess = false
        }
        case attachToPID(AttachToPIDOptions)
        
        struct AttachToURLOptions {
            var url: URL
            var waitForProcess = false
        }
        case attachToURL(AttachToURLOptions)
    }
    private(set) var configuration: Configuration?
    
    private var process: LLDBProcess?
    
    func launch(_ request: DebugAdapter.LaunchRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        do {
            guard let body = request.body else {
                throw AdapterError.invalidArguments(reason: "Missing `launch` request body.")
            }
            
            let launchPath = try body.get(String.self, for: "program")
            let launchURL = URL(fileURLWithPath: launchPath)
            
            var options = Configuration.LaunchOptions(url: launchURL)
            
            options.arguments = try body.getIfPresent([String].self, for: "args")
            options.environment = try body.getIfPresent([String: String].self, for: "env")
            let cwd = try body.getIfPresent(String.self, for: "cwd")
            options.currentDirectoryURL = cwd != nil ? URL(fileURLWithPath: cwd!, isDirectory: true) : nil
            
            var architecture: Architecture?
            if let archString = try body.getIfPresent(String.self, for: "arch") {
                architecture = Architecture(rawValue: archString)
                if architecture == nil {
                    throw AdapterError.invalidArguments(reason: "Unknown architecture `\(archString)`.")
                }
            }
            else if let runInRosetta = try body.getIfPresent(Bool.self, for: "runInRosetta") {
                if runInRosetta {
                    options.architecture = .x86_64
                }
            }
            
            configuration = .launch(options)
            debugStartRequest = .launch(request, replyHandler)
            connection.send(DebugAdapter.InitializedEvent())
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func attach(_ request: DebugAdapter.AttachRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        guard let body = request.body else {
            replyHandler(.failure(AdapterError.invalidArguments(reason: "Missing `attach` request body.")))
            return
        }
        
        do {
            if let pid = try body.getIfPresent(Int.self, for: "pid") {
                // Process Identifier
                var options = Configuration.AttachToPIDOptions(pid: pid_t(pid))
                options.waitForProcess = try body.getIfPresent(Bool.self, for: "wait") ?? false
                configuration = .attachToPID(options)
            }
            else if let attachPath = try body.getIfPresent(String.self, for: "program") {
                // Process Path
                let attachURL = URL(fileURLWithPath: attachPath)
                var options = Configuration.AttachToURLOptions(url: attachURL)
                options.waitForProcess = try body.getIfPresent(Bool.self, for: "wait") ?? false
                configuration = .attachToURL(options)
            }
            else {
                replyHandler(.failure(AdapterError.invalidArguments(reason: "No pid or process name specified for `attach` request.")))
                return
            }
            
            debugStartRequest = .attach(request, replyHandler)
            connection.send(DebugAdapter.InitializedEvent())
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func configurationDone(_ request: DebugAdapter.ConfigurationDoneRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        do {
            guard let debugger = debugger else {
                throw AdapterError.invalidArguments(reason: "No `initialize` request was sent before `configurationDone`.")
            }
            
            guard let configuration = configuration else {
                throw AdapterError.invalidArguments(reason: "No `launch` or `attach` request was sent before `configurationDone`.")
            }
            
            let startMethod: DebugAdapter.ProcessEvent.StartMethod
            
            let process: LLDBProcess
            var fallbackName: String?
            switch configuration {
                case .launch(let options):
                    startMethod = .launch
                    fallbackName = options.url.lastPathComponent
                    
                    let target = try debugger.createTarget(with: options.url, architecture: options.architecture?.rawValue)
                    
                    let launchOptions = LLDBLaunchOptions()
                    launchOptions.arguments = options.arguments
                    launchOptions.environment = options.environment
                    launchOptions.currentDirectoryURL = options.currentDirectoryURL
                    
                    process = try target.launch(with: launchOptions)
                    
                case .attachToPID(let options):
                    startMethod = .attach
                    
                    let target = try debugger.findTarget(withProcessIdentifier: options.pid)
                    
                    let attachOptions = LLDBAttachOptions()
                    attachOptions.waitForLaunch = options.waitForProcess
                    
                    process = try target.attach(with: attachOptions)
                    
                case .attachToURL(let options):
                    startMethod = .attach
                    fallbackName = options.url.lastPathComponent
                    
                    let target = try debugger.findTarget(with: options.url, architecture: nil)
                    
                    let attachOptions = LLDBAttachOptions()
                    attachOptions.waitForLaunch = options.waitForProcess
                    
                    process = try target.attach(with: attachOptions)
            }
            
            self.process = process
            
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
            
            replyHandler(.success(()))
            
            // Process event
            let processIdentifier = process.processIdentifier
            let runningApplication = NSRunningApplication(processIdentifier: processIdentifier)
            let name = runningApplication?.localizedName ?? fallbackName ?? "(unknown)"
            
            var event = DebugAdapter.ProcessEvent(name: name)
            event.startMethod = startMethod
            event.isLocalProcess = true
            event.systemProcessId = Int(processIdentifier)
            connection.send(event)
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
            
            replyHandler(.failure(error))
        }
    }
    
    // MARK: - Breakpoints
    
    private var _nextBreakpointId = 1
    private var nextBreakpointId: Int {
        let id = _nextBreakpointId
        if _nextBreakpointId == Int.max {
            _nextBreakpointId = 1
        }
        else {
            _nextBreakpointId += 1
        }
        return id
    }
    
    var breakpointsByID: [Int: DebugAdapter.Breakpoint] = [:]
    
    private(set) var sourceBreakpointIDs: [URL: Set<Int>] = [:]
    private(set) var sourceBreakpointsByID: [URL: [Int: DebugAdapter.SourceBreakpoint]] = [:]
    
    private func standardizedFileURL(forPath path: String, isDirectory: Bool) -> URL {
        var fileURL = URL(fileURLWithPath: path, isDirectory: isDirectory)
        fileURL.standardize()
        fileURL.standardizeVolumeInFileURL()
        return fileURL
    }
    
    func setBreakpoints(_ request: DebugAdapter.SetBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetBreakpointsRequest.Result, Error>) -> ()) {
        let source = request.source
        
        guard let path = source.path else {
            replyHandler(.failure(AdapterError.invalidArguments(reason: "Breakpoint source path is missing.")))
            return
        }
        
        let fileURL = standardizedFileURL(forPath: path, isDirectory: false)
        
        // Create new breakpoints
        var breakpoints: [DebugAdapter.Breakpoint] = []
        var breakpointsIDs: Set<Int> = []
        var sourceBreakpointsByID: [Int: DebugAdapter.SourceBreakpoint] = [:]
        
        let previousBreakpointIDs = sourceBreakpointIDs[fileURL] ?? []
        
        for id in previousBreakpointIDs {
            sourceBreakpointsByID[id] = nil
        }
        
        for sourceBreakpoint in request.breakpoints ?? [] {
            let id = nextBreakpointId
            
            var breakpoint = DebugAdapter.Breakpoint()
            breakpoint.id = id
            
            breakpoint.line = sourceBreakpoint.line
            breakpoint.column = sourceBreakpoint.column
            
            breakpoint.verified = false
            
            breakpoint.source = source
            
            breakpoints.append(breakpoint)
            breakpointsIDs.insert(id)
            sourceBreakpointsByID[id] = sourceBreakpoint
            breakpointsByID[id] = breakpoint
        }
        
        // Update active session
        
        
        sourceBreakpointIDs[fileURL] = breakpointsIDs.count > 0 ? breakpointsIDs : nil
        self.sourceBreakpointsByID[fileURL] = sourceBreakpointsByID.count > 0 ? sourceBreakpointsByID : nil
        
        replyHandler(.success(.init(breakpoints: breakpoints)))
    }
    
    private(set) var functionBreakpointIDs: Set<Int> = []
    private(set) var functionBreakpointsByID: [Int: DebugAdapter.FunctionBreakpoint] = [:]
    
    func setFunctionBreakpoints(_ request: DebugAdapter.SetFunctionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetFunctionBreakpointsRequest.Result?, Error>) -> ()) {
        // Create new breakpoints
        var breakpoints: [DebugAdapter.Breakpoint] = []
        var breakpointIDs: Set<Int> = []
        var functionBreakpointsByID: [Int: DebugAdapter.FunctionBreakpoint] = [:]
        
        let previousBreakpointIDs = functionBreakpointIDs
        
        for id in previousBreakpointIDs {
            breakpointsByID[id] = nil
        }
        
        for functionBreakpoint in request.breakpoints {
            let id = nextBreakpointId
            
            var breakpoint = DebugAdapter.Breakpoint()
            breakpoint.id = id
            breakpoint.verified = false
            
            breakpoints.append(breakpoint)
            breakpointIDs.insert(id)
            functionBreakpointsByID[id] = functionBreakpoint
            breakpointsByID[id] = breakpoint
        }
        
        functionBreakpointIDs = breakpointIDs
        self.functionBreakpointsByID = functionBreakpointsByID
        
        // Update active session
        
        
        replyHandler(.success(.init(breakpoints: breakpoints)))
    }
    
    private(set) var exceptionFiltersByID: [Int: String] = [:]
    
    func setExceptionBreakpoints(_ request: DebugAdapter.SetExceptionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetExceptionBreakpointsRequest.Result?, Error>) -> ()) {
        var exceptionFiltersByID: [Int: String] = [:]
        var breakpoints: [DebugAdapter.Breakpoint] = []
        
        let previousBreakpointIDs = exceptionFiltersByID.keys
        
        if let filters = request.filters {
            for filter in filters {
                let id = nextBreakpointId
                
                var breakpoint = DebugAdapter.Breakpoint()
                breakpoint.id = id
                breakpoint.verified = false
                exceptionFiltersByID[id] = filter
                breakpointsByID[id] = breakpoint
                breakpoints.append(breakpoint)
            }
        }
        
        self.exceptionFiltersByID = exceptionFiltersByID
        
        // Update active session
        
        
        replyHandler(.success(.init(breakpoints: breakpoints)))
    }
    
    // MARK: - Execution
    
    func disconnect(_ request: DebugAdapter.DisconnectRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        defer {
            process = nil
            configuration = nil
        }
        
        do {
            if let configuration = configuration, let process = process {
                switch configuration {
                    case .launch:
                        try process.kill()
                    case .attachToPID, .attachToURL:
                        try process.detach()
                }
            }
            
            replyHandler(.success(()))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func pause(_ request: DebugAdapter.PauseRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        
    }
    
    func `continue`(_ request: DebugAdapter.ContinueRequest, replyHandler: @escaping (Result<DebugAdapter.ContinueRequest.Result, Error>) -> ()) {
        
    }
    
    func next(_ request: DebugAdapter.NextRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        
    }
    
    func stepIn(_ request: DebugAdapter.StepInRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        
    }
    
    func stepOut(_ request: DebugAdapter.StepOutRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        
    }
    
    // MARK: - Threads
    
    func threads(_ request: DebugAdapter.ThreadsRequest, replyHandler: @escaping (Result<DebugAdapter.ThreadsRequest.Result, Error>) -> ()) {
        
    }
    
    func stackTrace(_ request: DebugAdapter.StackTraceRequest, replyHandler: @escaping (Result<DebugAdapter.StackTraceRequest.Result, Error>) -> ()) {
        
    }
    
    func scopes(_ request: DebugAdapter.ScopesRequest, replyHandler: @escaping (Result<DebugAdapter.ScopesRequest.Result, Error>) -> ()) {
        
    }
    
    func exceptionInfo(_ request: DebugAdapter.ExceptionInfoRequest, replyHandler: @escaping (Result<DebugAdapter.ExceptionInfoRequest.Result, Error>) -> ()) {
        
    }
    
    func variables(_ request: DebugAdapter.VariablesRequest, replyHandler: @escaping (Result<DebugAdapter.VariablesRequest.Result, Error>) -> ()) {
        
    }
    
    func evaluate(_ request: DebugAdapter.EvaluateRequest, replyHandler: @escaping (Result<DebugAdapter.EvaluateRequest.Result, Error>) -> ()) {
        
    }
    
    func completions(_ request: DebugAdapter.CompletionsRequest, replyHandler: @escaping (Result<DebugAdapter.CompletionsRequest.Result, Error>) -> ()) {
        
    }
}
