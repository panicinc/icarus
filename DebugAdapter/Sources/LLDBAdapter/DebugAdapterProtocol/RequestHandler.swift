import Foundation

/// Base protocol for any request handler.
public protocol DebugAdapterRequestHandler {
    /// The primary method invoked to handle an incoming request.
    func handleRequest(_ request: DebugAdapterConnection.IncomingRequest)
}

/// Request handler for the standard set of Debug Adapter Protocol server/adapter-targeted requests.
public protocol DebugAdapterServerRequestHandler: DebugAdapterRequestHandler {
    associatedtype AttachParameters: Codable & Sendable = JSONValue
    func attach(_ request: DebugAdapter.AttachRequest<AttachParameters>, replyHandler: @escaping (Result<(), Error>) -> Void)
    func breakpointLocations(_ request: DebugAdapter.BreakpointLocationsRequest, replyHandler: @escaping (Result<DebugAdapter.BreakpointLocationsRequest.Result, Error>) -> Void)
    func completions(_ request: DebugAdapter.CompletionsRequest, replyHandler: @escaping (Result<DebugAdapter.CompletionsRequest.Result, Error>) -> Void)
    func configurationDone(_ request: DebugAdapter.ConfigurationDoneRequest, replyHandler: @escaping (Result<(), Error>) -> Void)
    func `continue`(_ request: DebugAdapter.ContinueRequest, replyHandler: @escaping (Result<DebugAdapter.ContinueRequest.Result, Error>) -> Void)
    func dataBreakpointInfo(_ request: DebugAdapter.DataBreakpointInfoRequest, replyHandler: @escaping (Result<DebugAdapter.DataBreakpointInfoRequest.Result, Error>) -> Void)
    func disassemble(_ request: DebugAdapter.DisassembleRequest, replyHandler: @escaping (Result<DebugAdapter.DisassembleRequest.Result?, Error>) -> Void)
    func disconnect(_ request: DebugAdapter.DisconnectRequest, replyHandler: @escaping (Result<(), Error>) -> Void)
    func evaluate(_ request: DebugAdapter.EvaluateRequest, replyHandler: @escaping (Result<DebugAdapter.EvaluateRequest.Result, Error>) -> Void)
    func goto(_ request: DebugAdapter.GotoRequest, replyHandler: @escaping (Result<(), Error>) -> Void)
    func exceptionInfo(_ request: DebugAdapter.ExceptionInfoRequest, replyHandler: @escaping (Result<DebugAdapter.ExceptionInfoRequest.Result, Error>) -> Void)
    func gotoTargets(_ request: DebugAdapter.GotoTargetsRequest, replyHandler: @escaping (Result<DebugAdapter.GotoTargetsRequest.Result, Error>) -> Void)
    func initialize(_ request: DebugAdapter.InitializeRequest, replyHandler: @escaping (Result<DebugAdapter.InitializeRequest.Result?, Error>) -> Void)
    associatedtype LaunchParameters: Codable & Sendable = JSONValue
    func launch(_ request: DebugAdapter.LaunchRequest<LaunchParameters>, replyHandler: @escaping (Result<(), Error>) -> Void)
    func loadedSources(_ request: DebugAdapter.LoadedSourcesRequest, replyHandler: @escaping (Result<DebugAdapter.LoadedSourcesRequest.Result, Error>) -> Void)
    func locations(_ request: DebugAdapter.LocationsRequest, replyHandler: @escaping (Result<DebugAdapter.LocationsRequest.Result, Error>) -> Void)
    func next(_ request: DebugAdapter.NextRequest, replyHandler: @escaping (Result<(), Error>) -> Void)
    func pause(_ request: DebugAdapter.PauseRequest, replyHandler: @escaping (Result<(), Error>) -> Void)
    func readMemory(_ request: DebugAdapter.ReadMemoryRequest, replyHandler: @escaping (Result<DebugAdapter.ReadMemoryRequest.Result?, Error>) -> Void)
    func restart(_ request: DebugAdapter.IncomingRestartRequest<LaunchParameters, AttachParameters>) throws
    func restartFrame(_ request: DebugAdapter.RestartFrameRequest, replyHandler: @escaping (Result<(), Error>) -> Void)
    func reverseContinue(_ request: DebugAdapter.ReverseContinueRequest, replyHandler: @escaping (Result<(), Error>) -> Void)
    func scopes(_ request: DebugAdapter.ScopesRequest, replyHandler: @escaping (Result<DebugAdapter.ScopesRequest.Result, Error>) -> Void)
    func setBreakpoints(_ request: DebugAdapter.SetBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetBreakpointsRequest.Result, Error>) -> Void)
    func setDataBreakpoints(_ request: DebugAdapter.SetDataBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetDataBreakpointsRequest.Result, Error>) -> Void)
    func setExceptionBreakpoints(_ request: DebugAdapter.SetExceptionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetExceptionBreakpointsRequest.Result?, Error>) -> Void)
    func setExpression(_ request: DebugAdapter.SetExpressionRequest, replyHandler: @escaping (Result<DebugAdapter.SetExpressionRequest.Result, Error>) -> Void)
    func setFunctionBreakpoints(_ request: DebugAdapter.SetFunctionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetFunctionBreakpointsRequest.Result, Error>) -> Void)
    func setInstructionBreakpoints(_ request: DebugAdapter.SetInstructionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetInstructionBreakpointsRequest.Result, Error>) -> Void)
    func setVariable(_ request: DebugAdapter.SetVariableRequest, replyHandler: @escaping (Result<DebugAdapter.SetVariableRequest.Result, Error>) -> Void)
    func source(_ request: DebugAdapter.SourceRequest, replyHandler: @escaping (Result<DebugAdapter.SourceRequest.Result, Error>) -> Void)
    func stackTrace(_ request: DebugAdapter.StackTraceRequest, replyHandler: @escaping (Result<DebugAdapter.StackTraceRequest.Result, Error>) -> Void)
    func stepBack(_ request: DebugAdapter.StepBackRequest, replyHandler: @escaping (Result<(), Error>) -> Void)
    func stepIn(_ request: DebugAdapter.StepInRequest, replyHandler: @escaping (Result<(), Error>) -> Void)
    func stepInTargets(_ request: DebugAdapter.StepInTargetsRequest, replyHandler: @escaping (Result<DebugAdapter.StepInTargetsRequest.Result, Error>) -> Void)
    func stepOut(_ request: DebugAdapter.StepOutRequest, replyHandler: @escaping (Result<(), Error>) -> Void)
    func terminate(_ request: DebugAdapter.TerminateRequest, replyHandler: @escaping (Result<(), Error>) -> Void)
    func terminateThreads(_ request: DebugAdapter.TerminateThreadsRequest, replyHandler: @escaping (Result<(), Error>) -> Void)
    func threads(_ request: DebugAdapter.ThreadsRequest, replyHandler: @escaping (Result<DebugAdapter.ThreadsRequest.Result, Error>) -> Void)
    func variables(_ request: DebugAdapter.VariablesRequest, replyHandler: @escaping (Result<DebugAdapter.VariablesRequest.Result, Error>) -> Void)
    func writeMemory(_ request: DebugAdapter.WriteMemoryRequest, replyHandler: @escaping (Result<DebugAdapter.WriteMemoryRequest.Result?, Error>) -> Void)
}

/// Request handler for the standard set of Debug Adapter Protocol client-targeted requests.
public protocol DebugAdapterClientRequestHandler: DebugAdapterRequestHandler {
    func runInTerminal(_ request: DebugAdapter.RunInTerminalRequest, replyHandler: @escaping (Result<DebugAdapter.RunInTerminalRequest.Result, Error>) -> Void)
    func startDebugging(_ request: DebugAdapter.StartDebuggingRequest, replyHandler: @escaping (Result<DebugAdapter.StartDebuggingRequest.Result, Error>) -> Void)
}

public extension DebugAdapterServerRequestHandler {
    func handleRequest(_ request: DebugAdapterConnection.IncomingRequest) {
        do {
            try performDefaultHandling(for: request)
        }
        catch {
            request.reject(throwing: error)
        }
    }
    
    /// Performs the default handling for supported request types.
    /// Request types that are not supported will return with DebugAdapterConnection.ResponseError.unsupportedRequest(request).
    func performDefaultHandling(for request: DebugAdapterConnection.IncomingRequest) throws {
        switch request.command {
        case DebugAdapter.AttachRequest<AttachParameters>.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.AttachRequest<AttachParameters>.self)
            attach(request, replyHandler: replyHandler)
            
        case DebugAdapter.BreakpointLocationsRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.BreakpointLocationsRequest.self)
            breakpointLocations(request, replyHandler: replyHandler)
            
        case DebugAdapter.CompletionsRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.CompletionsRequest.self)
            completions(request, replyHandler: replyHandler)
            
        case DebugAdapter.ConfigurationDoneRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.ConfigurationDoneRequest.self)
            configurationDone(request, replyHandler: replyHandler)
            
        case DebugAdapter.ContinueRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.ContinueRequest.self)
            `continue`(request, replyHandler: replyHandler)
            
        case DebugAdapter.DataBreakpointInfoRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.DataBreakpointInfoRequest.self)
            dataBreakpointInfo(request, replyHandler: replyHandler)
            
        case DebugAdapter.DisassembleRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.DisassembleRequest.self)
            disassemble(request, replyHandler: replyHandler)
            
        case DebugAdapter.DisconnectRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.DisconnectRequest.self)
            disconnect(request, replyHandler: replyHandler)
            
        case DebugAdapter.EvaluateRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.EvaluateRequest.self)
            evaluate(request, replyHandler: replyHandler)
            
        case DebugAdapter.ExceptionInfoRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.ExceptionInfoRequest.self)
            exceptionInfo(request, replyHandler: replyHandler)
            
        case DebugAdapter.GotoRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.GotoRequest.self)
            goto(request, replyHandler: replyHandler)
            
        case DebugAdapter.GotoTargetsRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.GotoTargetsRequest.self)
            gotoTargets(request, replyHandler: replyHandler)
            
        case DebugAdapter.InitializeRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.InitializeRequest.self)
            initialize(request, replyHandler: replyHandler)
            
        case DebugAdapter.LaunchRequest<LaunchParameters>.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.LaunchRequest<LaunchParameters>.self)
            launch(request, replyHandler: replyHandler)
            
        case DebugAdapter.LoadedSourcesRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.LoadedSourcesRequest.self)
            loadedSources(request, replyHandler: replyHandler)
            
        case DebugAdapter.LocationsRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.LocationsRequest.self)
            locations(request, replyHandler: replyHandler)
            
        case DebugAdapter.NextRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.NextRequest.self)
            next(request, replyHandler: replyHandler)
            
        case DebugAdapter.PauseRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.PauseRequest.self)
            pause(request, replyHandler: replyHandler)
            
        case DebugAdapter.ReadMemoryRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.ReadMemoryRequest.self)
            readMemory(request, replyHandler: replyHandler)
            
        case DebugAdapter.RestartRequest<LaunchParameters>.command:
            try restart(DebugAdapter.IncomingRestartRequest(request))
            
        case DebugAdapter.RestartFrameRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.RestartFrameRequest.self)
            restartFrame(request, replyHandler: replyHandler)
            
        case DebugAdapter.ReverseContinueRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.ReverseContinueRequest.self)
            reverseContinue(request, replyHandler: replyHandler)
            
        case DebugAdapter.ScopesRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.ScopesRequest.self)
            scopes(request, replyHandler: replyHandler)
            
        case DebugAdapter.SetBreakpointsRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.SetBreakpointsRequest.self)
            setBreakpoints(request, replyHandler: replyHandler)
            
        case DebugAdapter.SetDataBreakpointsRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.SetDataBreakpointsRequest.self)
            setDataBreakpoints(request, replyHandler: replyHandler)

        case DebugAdapter.SetExceptionBreakpointsRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.SetExceptionBreakpointsRequest.self)
            setExceptionBreakpoints(request, replyHandler: replyHandler)

        case DebugAdapter.SetExpressionRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.SetExpressionRequest.self)
            setExpression(request, replyHandler: replyHandler)

        case DebugAdapter.SetFunctionBreakpointsRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.SetFunctionBreakpointsRequest.self)
            setFunctionBreakpoints(request, replyHandler: replyHandler)
            
        case DebugAdapter.SetInstructionBreakpointsRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.SetInstructionBreakpointsRequest.self)
            setInstructionBreakpoints(request, replyHandler: replyHandler)

        case DebugAdapter.SetVariableRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.SetVariableRequest.self)
            setVariable(request, replyHandler: replyHandler)

        case DebugAdapter.SourceRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.SourceRequest.self)
            source(request, replyHandler: replyHandler)

        case DebugAdapter.StackTraceRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.StackTraceRequest.self)
            stackTrace(request, replyHandler: replyHandler)
            
        case DebugAdapter.StepBackRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.StepBackRequest.self)
            stepBack(request, replyHandler: replyHandler)

        case DebugAdapter.StepInRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.StepInRequest.self)
            stepIn(request, replyHandler: replyHandler)
            
        case DebugAdapter.StepInTargetsRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.StepInTargetsRequest.self)
            stepInTargets(request, replyHandler: replyHandler)

        case DebugAdapter.StepOutRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.StepOutRequest.self)
            stepOut(request, replyHandler: replyHandler)
            
        case DebugAdapter.TerminateRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.TerminateRequest.self)
            terminate(request, replyHandler: replyHandler)
            
        case DebugAdapter.TerminateThreadsRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.TerminateThreadsRequest.self)
            terminateThreads(request, replyHandler: replyHandler)

        case DebugAdapter.ThreadsRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.ThreadsRequest.self)
            threads(request, replyHandler: replyHandler)

        case DebugAdapter.VariablesRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.VariablesRequest.self)
            variables(request, replyHandler: replyHandler)
            
        case DebugAdapter.WriteMemoryRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.WriteMemoryRequest.self)
            writeMemory(request, replyHandler: replyHandler)
            
        default:
            throw DebugAdapterConnection.ResponseError.unsupportedRequest(request.command)
        }
    }
    
    func attach(_ request: DebugAdapter.AttachRequest<AttachParameters>, replyHandler: @escaping (Result<(), Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func breakpointLocations(_ request: DebugAdapter.BreakpointLocationsRequest, replyHandler: @escaping (Result<DebugAdapter.BreakpointLocationsRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func completions(_ request: DebugAdapter.CompletionsRequest, replyHandler: @escaping (Result<DebugAdapter.CompletionsRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func configurationDone(_ request: DebugAdapter.ConfigurationDoneRequest, replyHandler: @escaping (Result<(), Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func `continue`(_ request: DebugAdapter.ContinueRequest, replyHandler: @escaping (Result<DebugAdapter.ContinueRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func dataBreakpointInfo(_ request: DebugAdapter.DataBreakpointInfoRequest, replyHandler: @escaping (Result<DebugAdapter.DataBreakpointInfoRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func disassemble(_ request: DebugAdapter.DisassembleRequest, replyHandler: @escaping (Result<DebugAdapter.DisassembleRequest.Result?, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func disconnect(_ request: DebugAdapter.DisconnectRequest, replyHandler: @escaping (Result<(), Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func evaluate(_ request: DebugAdapter.EvaluateRequest, replyHandler: @escaping (Result<DebugAdapter.EvaluateRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func exceptionInfo(_ request: DebugAdapter.ExceptionInfoRequest, replyHandler: @escaping (Result<DebugAdapter.ExceptionInfoRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func goto(_ request: DebugAdapter.GotoRequest, replyHandler: @escaping (Result<(), Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func gotoTargets(_ request: DebugAdapter.GotoTargetsRequest, replyHandler: @escaping (Result<DebugAdapter.GotoTargetsRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func initialize(_ request: DebugAdapter.InitializeRequest, replyHandler: @escaping (Result<DebugAdapter.InitializeRequest.Result?, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func launch(_ request: DebugAdapter.LaunchRequest<LaunchParameters>, replyHandler: @escaping (Result<(), Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func loadedSources(_ request: DebugAdapter.LoadedSourcesRequest, replyHandler: @escaping (Result<DebugAdapter.LoadedSourcesRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func locations(_ request: DebugAdapter.LocationsRequest, replyHandler: @escaping (Result<DebugAdapter.LocationsRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func next(_ request: DebugAdapter.NextRequest, replyHandler: @escaping (Result<(), Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func pause(_ request: DebugAdapter.PauseRequest, replyHandler: @escaping (Result<(), Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func readMemory(_ request: DebugAdapter.ReadMemoryRequest, replyHandler: @escaping (Result<DebugAdapter.ReadMemoryRequest.Result?, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func restart(_ request: DebugAdapter.IncomingRestartRequest<LaunchParameters, AttachParameters>) {
        request.reject(throwing: DebugAdapterConnection.ResponseError.unsupportedRequest(type(of: request).command))
    }
    
    func restartFrame(_ request: DebugAdapter.RestartFrameRequest, replyHandler: @escaping (Result<(), Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func reverseContinue(_ request: DebugAdapter.ReverseContinueRequest, replyHandler: @escaping (Result<(), Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func scopes(_ request: DebugAdapter.ScopesRequest, replyHandler: @escaping (Result<DebugAdapter.ScopesRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func setBreakpoints(_ request: DebugAdapter.SetBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetBreakpointsRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func setDataBreakpoints(_ request: DebugAdapter.SetDataBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetDataBreakpointsRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func setExceptionBreakpoints(_ request: DebugAdapter.SetExceptionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetExceptionBreakpointsRequest.Result?, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func setExpression(_ request: DebugAdapter.SetExpressionRequest, replyHandler: @escaping (Result<DebugAdapter.SetExpressionRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func setFunctionBreakpoints(_ request: DebugAdapter.SetFunctionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetFunctionBreakpointsRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func setInstructionBreakpoints(_ request: DebugAdapter.SetInstructionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetInstructionBreakpointsRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func setVariable(_ request: DebugAdapter.SetVariableRequest, replyHandler: @escaping (Result<DebugAdapter.SetVariableRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func source(_ request: DebugAdapter.SourceRequest, replyHandler: @escaping (Result<DebugAdapter.SourceRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func stackTrace(_ request: DebugAdapter.StackTraceRequest, replyHandler: @escaping (Result<DebugAdapter.StackTraceRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func stepBack(_ request: DebugAdapter.StepBackRequest, replyHandler: @escaping (Result<(), Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func stepIn(_ request: DebugAdapter.StepInRequest, replyHandler: @escaping (Result<(), Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func stepInTargets(_ request: DebugAdapter.StepInTargetsRequest, replyHandler: @escaping (Result<DebugAdapter.StepInTargetsRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func stepOut(_ request: DebugAdapter.StepOutRequest, replyHandler: @escaping (Result<(), Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func terminate(_ request: DebugAdapter.TerminateRequest, replyHandler: @escaping (Result<(), Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func terminateThreads(_ request: DebugAdapter.TerminateThreadsRequest, replyHandler: @escaping (Result<(), Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func threads(_ request: DebugAdapter.ThreadsRequest, replyHandler: @escaping (Result<DebugAdapter.ThreadsRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func variables(_ request: DebugAdapter.VariablesRequest, replyHandler: @escaping (Result<DebugAdapter.VariablesRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func writeMemory(_ request: DebugAdapter.WriteMemoryRequest, replyHandler: @escaping (Result<DebugAdapter.WriteMemoryRequest.Result?, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
}

public extension DebugAdapterClientRequestHandler {
    func handleRequest(_ request: DebugAdapterConnection.IncomingRequest) {
        do {
            try performDefaultHandling(for: request)
        }
        catch {
            request.reject(throwing: error)
        }
    }
    
    /// Performs the default handling for supported request types.
    /// Request types that are not supported will return with DebugAdapterConnection.ResponseError.unsupportedRequest(request).
    func performDefaultHandling(for request: DebugAdapterConnection.IncomingRequest) throws {
        switch request.command {
        case DebugAdapter.RunInTerminalRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.RunInTerminalRequest.self)
            runInTerminal(request, replyHandler: replyHandler)
            
        case DebugAdapter.StartDebuggingRequest.command:
            let (request, replyHandler) = try request.decodeForReply(DebugAdapter.StartDebuggingRequest.self)
            startDebugging(request, replyHandler: replyHandler)
            
        default:
            throw DebugAdapterConnection.ResponseError.unsupportedRequest(request.command)
        }
    }
    
    func runInTerminal(_ request: DebugAdapter.RunInTerminalRequest, replyHandler: @escaping (Result<DebugAdapter.RunInTerminalRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
    
    func startDebugging(_ request: DebugAdapter.StartDebuggingRequest, replyHandler: @escaping (Result<DebugAdapter.StartDebuggingRequest.Result, Error>) -> Void) {
        replyHandler(.failure(DebugAdapterConnection.ResponseError.unsupportedRequest(request)))
    }
}

extension DebugAdapter {
    public struct IncomingRestartRequest<LaunchParameters, AttachParameters> where LaunchParameters: Sendable & Codable, AttachParameters: Sendable & Codable {
        public static var command: String { "restart" }
        
        fileprivate let request: DebugAdapterConnection.IncomingRequest
        
        fileprivate init(_ request: DebugAdapterConnection.IncomingRequest) {
            self.request = request
        }
        
        public func decodeForReplyAsLaunch() throws -> (DebugAdapter.RestartRequest<LaunchParameters>, (Result<(), Error>) -> Void) {
            return try request.decodeForReply(DebugAdapter.RestartRequest<LaunchParameters>.self)
        }
        
        public func decodeForReplyAsAttach() throws -> (DebugAdapter.RestartRequest<AttachParameters>, (Result<(), Error>) -> Void) {
            return try request.decodeForReply(DebugAdapter.RestartRequest<AttachParameters>.self)
        }
        
        public func reject(throwing error: Error) {
            return request.reject(throwing: error)
        }
    }
}
