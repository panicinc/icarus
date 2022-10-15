import Darwin
import Dispatch

class Adapter: DebugAdapterServerRequestHandler {
    static internal let shared = Adapter()
    
    let connection = DebugAdapterConnection(transport: DebugAdapterFileHandleTransport())
    let queue = DispatchQueue(label: "com.panic.lldb-adapter")
    
    // MARK: Lifecycle
    
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
    
    // MARK: Configuration
    
    private struct ClientOptions {
        var clientID: String?
        var clientName: String?
        var adapterID: String?
        
        var linesStartAt1 = true
        var columnsStartAt1 = true
    }
    private var clientOptions = ClientOptions()
    
    func initialize(_ request: DebugAdapter.InitializeRequest, replyHandler: @escaping (Result<DebugAdapter.InitializeRequest.Result?, Error>) -> ()) {
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
        
        // let caughtExceptionsFilter = DebugAdapter.ExceptionBreakpointFilter(filter: "*", label: "All Exceptions")
        // 
        // var uncaughtExceptionsFilter = DebugAdapter.ExceptionBreakpointFilter(filter: "uncaught", label: "Uncaught Exceptions")
        // uncaughtExceptionsFilter.defaultValue = true
        
        // capabilities.exceptionBreakpointFilters = [caughtExceptionsFilter, uncaughtExceptionsFilter]
        
        replyHandler(.success(capabilities))
    }
    
    func launch(_ request: DebugAdapter.LaunchRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        
    }
    
    func attach(_ request: DebugAdapter.AttachRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        
    }
    
    func configurationDone(_ request: DebugAdapter.ConfigurationDoneRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        
    }
    
    // MARK: Breakpoints
    
    func setBreakpoints(_ request: DebugAdapter.SetBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetBreakpointsRequest.Result, Error>) -> ()) {
        
    }
    
    func setFunctionBreakpoints(_ request: DebugAdapter.SetFunctionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetFunctionBreakpointsRequest.Result?, Error>) -> ()) {
        
    }
    
    func setExceptionBreakpoints(_ request: DebugAdapter.SetExceptionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetExceptionBreakpointsRequest.Result?, Error>) -> ()) {
        
    }
    
    // MARK: Execution
    
    func disconnect(_ request: DebugAdapter.DisconnectRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        
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
    
    // MARK: Threads
    
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
