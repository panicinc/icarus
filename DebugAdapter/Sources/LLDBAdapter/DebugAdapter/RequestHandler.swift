import Foundation

/// Base protocol for any request handler.
public protocol DebugAdapterRequestHandler {
    /// The primary method invoked to parse and handle a request.
    func handleRequest(forCommand command: String, data: Data, connection: DebugAdapterConnection) throws
}

/// Request handler for the standard set of Debug Adapter Protocol "server" (adapter-targeted) requests.
public protocol DebugAdapterServerRequestHandler: DebugAdapterRequestHandler {
    associatedtype AttachParameters: Codable
    func attach(_ request: DebugAdapter.AttachRequest<AttachParameters>, replyHandler: @escaping (Result<(), Error>) -> ())
    func breakpointLocations(_ request: DebugAdapter.BreakpointLocationsRequest, replyHandler: @escaping (Result<DebugAdapter.BreakpointLocationsRequest.Result, Error>) -> ())
    func completions(_ request: DebugAdapter.CompletionsRequest, replyHandler: @escaping (Result<DebugAdapter.CompletionsRequest.Result, Error>) -> ())
    func configurationDone(_ request: DebugAdapter.ConfigurationDoneRequest, replyHandler: @escaping (Result<(), Error>) -> ())
    func `continue`(_ request: DebugAdapter.ContinueRequest, replyHandler: @escaping (Result<DebugAdapter.ContinueRequest.Result, Error>) -> ())
    func dataBreakpointInfo(_ request: DebugAdapter.DataBreakpointInfoRequest, replyHandler: @escaping (Result<DebugAdapter.DataBreakpointInfoRequest.Result, Error>) -> ())
    func disassemble(_ request: DebugAdapter.DisassembleRequest, replyHandler: @escaping (Result<DebugAdapter.DisassembleRequest.Result?, Error>) -> ())
    func disconnect(_ request: DebugAdapter.DisconnectRequest, replyHandler: @escaping (Result<(), Error>) -> ())
    func evaluate(_ request: DebugAdapter.EvaluateRequest, replyHandler: @escaping (Result<DebugAdapter.EvaluateRequest.Result, Error>) -> ())
    func goto(_ request: DebugAdapter.GotoRequest, replyHandler: @escaping (Result<(), Error>) -> ())
    func exceptionInfo(_ request: DebugAdapter.ExceptionInfoRequest, replyHandler: @escaping (Result<DebugAdapter.ExceptionInfoRequest.Result, Error>) -> ())
    func gotoTargets(_ request: DebugAdapter.GotoTargetsRequest, replyHandler: @escaping (Result<DebugAdapter.GotoTargetsRequest.Result, Error>) -> ())
    func initialize(_ request: DebugAdapter.InitializeRequest, replyHandler: @escaping (Result<DebugAdapter.InitializeRequest.Result?, Error>) -> ())
    associatedtype LaunchParameters: Codable
    func launch(_ request: DebugAdapter.LaunchRequest<LaunchParameters>, replyHandler: @escaping (Result<(), Error>) -> ())
    func loadedSources(_ request: DebugAdapter.LoadedSourcesRequest, replyHandler: @escaping (Result<DebugAdapter.LoadedSourcesRequest.Result, Error>) -> ())
    func next(_ request: DebugAdapter.NextRequest, replyHandler: @escaping (Result<(), Error>) -> ())
    func pause(_ request: DebugAdapter.PauseRequest, replyHandler: @escaping (Result<(), Error>) -> ())
    func readMemory(_ request: DebugAdapter.ReadMemoryRequest, replyHandler: @escaping (Result<DebugAdapter.ReadMemoryRequest.Result?, Error>) -> ())
    func restart(_ request: DebugAdapter.RestartRequest, replyHandler: @escaping (Result<(), Error>) -> ())
    func restartFrame(_ request: DebugAdapter.RestartFrameRequest, replyHandler: @escaping (Result<(), Error>) -> ())
    func reverseContinue(_ request: DebugAdapter.ReverseContinueRequest, replyHandler: @escaping (Result<(), Error>) -> ())
    func scopes(_ request: DebugAdapter.ScopesRequest, replyHandler: @escaping (Result<DebugAdapter.ScopesRequest.Result, Error>) -> ())
    func setBreakpoints(_ request: DebugAdapter.SetBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetBreakpointsRequest.Result, Error>) -> ())
    func setDataBreakpoints(_ request: DebugAdapter.SetDataBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetDataBreakpointsRequest.Result, Error>) -> ())
    func setExceptionBreakpoints(_ request: DebugAdapter.SetExceptionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetExceptionBreakpointsRequest.Result?, Error>) -> ())
    func setExpression(_ request: DebugAdapter.SetExpressionRequest, replyHandler: @escaping (Result<DebugAdapter.SetExpressionRequest.Result, Error>) -> ())
    func setFunctionBreakpoints(_ request: DebugAdapter.SetFunctionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetFunctionBreakpointsRequest.Result?, Error>) -> ())
    func setInstructionBreakpoints(_ request: DebugAdapter.SetInstructionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetInstructionBreakpointsRequest.Result, Error>) -> ())
    func setVariable(_ request: DebugAdapter.SetVariableRequest, replyHandler: @escaping (Result<DebugAdapter.SetVariableRequest.Result, Error>) -> ())
    func source(_ request: DebugAdapter.SourceRequest, replyHandler: @escaping (Result<DebugAdapter.SourceRequest.Result, Error>) -> ())
    func stackTrace(_ request: DebugAdapter.StackTraceRequest, replyHandler: @escaping (Result<DebugAdapter.StackTraceRequest.Result, Error>) -> ())
    func stepBack(_ request: DebugAdapter.StepBackRequest, replyHandler: @escaping (Result<(), Error>) -> ())
    func stepIn(_ request: DebugAdapter.StepInRequest, replyHandler: @escaping (Result<(), Error>) -> ())
    func stepInTargets(_ request: DebugAdapter.StepInTargetsRequest, replyHandler: @escaping (Result<DebugAdapter.StepInTargetsRequest.Result, Error>) -> ())
    func stepOut(_ request: DebugAdapter.StepOutRequest, replyHandler: @escaping (Result<(), Error>) -> ())
    func terminate(_ request: DebugAdapter.TerminateRequest, replyHandler: @escaping (Result<(), Error>) -> ())
    func terminateThreads(_ request: DebugAdapter.TerminateThreadsRequest, replyHandler: @escaping (Result<(), Error>) -> ())
    func threads(_ request: DebugAdapter.ThreadsRequest, replyHandler: @escaping (Result<DebugAdapter.ThreadsRequest.Result, Error>) -> ())
    func variables(_ request: DebugAdapter.VariablesRequest, replyHandler: @escaping (Result<DebugAdapter.VariablesRequest.Result, Error>) -> ())
    func writeMemory(_ request: DebugAdapter.WriteMemoryRequest, replyHandler: @escaping (Result<DebugAdapter.WriteMemoryRequest.Result?, Error>) -> ())
}

/// Request handler for the standard set of Debug Adapter Protocol "reverse" (client-targeted) requests.
public protocol DebugAdapterClientRequestHandler: DebugAdapterRequestHandler {
    func runInTerminal(_ request: DebugAdapter.RunInTerminalRequest, replyHandler: @escaping (Result<DebugAdapter.RunInTerminalRequest.Result, Error>) -> ())
}

public extension DebugAdapterServerRequestHandler {
    /// Handlers may override this method to perform special handling of standard or custom requests, and may invoke
    /// `performDefaultHanding(forCommand:data:token:reply:)` to delegate to the default implementation for requests not handled.
    func handleRequest(forCommand command: String, data: Data, connection: DebugAdapterConnection) throws {
        try performDefaultHandling(forCommand: command, data: data, connection: connection)
    }
    
    /// Performs the default handling for supported request types.
    /// Request types that are not supported will return with DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command).
    func performDefaultHandling(forCommand command: String, data: Data, connection: DebugAdapterConnection) throws {
        switch command {
        case DebugAdapter.AttachRequest<AttachParameters>.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.AttachRequest<AttachParameters>.self, from: data)
            attach(request, replyHandler: replyHandler)
            
        case DebugAdapter.BreakpointLocationsRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.BreakpointLocationsRequest.self, from: data)
            breakpointLocations(request, replyHandler: replyHandler)
            
        case DebugAdapter.CompletionsRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.CompletionsRequest.self, from: data)
            completions(request, replyHandler: replyHandler)
            
        case DebugAdapter.ConfigurationDoneRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.ConfigurationDoneRequest.self, from: data)
            configurationDone(request, replyHandler: replyHandler)
            
        case DebugAdapter.ContinueRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.ContinueRequest.self, from: data)
            `continue`(request, replyHandler: replyHandler)
            
        case DebugAdapter.DataBreakpointInfoRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.DataBreakpointInfoRequest.self, from: data)
            dataBreakpointInfo(request, replyHandler: replyHandler)
            
        case DebugAdapter.DisassembleRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.DisassembleRequest.self, from: data)
            disassemble(request, replyHandler: replyHandler)
            
        case DebugAdapter.DisconnectRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.DisconnectRequest.self, from: data)
            disconnect(request, replyHandler: replyHandler)
            
        case DebugAdapter.EvaluateRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.EvaluateRequest.self, from: data)
            evaluate(request, replyHandler: replyHandler)
            
        case DebugAdapter.ExceptionInfoRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.ExceptionInfoRequest.self, from: data)
            exceptionInfo(request, replyHandler: replyHandler)
            
        case DebugAdapter.GotoRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.GotoRequest.self, from: data)
            goto(request, replyHandler: replyHandler)
            
        case DebugAdapter.GotoTargetsRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.GotoTargetsRequest.self, from: data)
            gotoTargets(request, replyHandler: replyHandler)
            
        case DebugAdapter.InitializeRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.InitializeRequest.self, from: data)
            initialize(request, replyHandler: replyHandler)
            
        case DebugAdapter.LaunchRequest<LaunchParameters>.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.LaunchRequest<LaunchParameters>.self, from: data)
            launch(request, replyHandler: replyHandler)
            
        case DebugAdapter.LoadedSourcesRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.LoadedSourcesRequest.self, from: data)
            loadedSources(request, replyHandler: replyHandler)
            
        case DebugAdapter.NextRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.NextRequest.self, from: data)
            next(request, replyHandler: replyHandler)
            
        case DebugAdapter.PauseRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.PauseRequest.self, from: data)
            pause(request, replyHandler: replyHandler)
            
        case DebugAdapter.ReadMemoryRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.ReadMemoryRequest.self, from: data)
            readMemory(request, replyHandler: replyHandler)
            
        case DebugAdapter.RestartRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.RestartRequest.self, from: data)
            restart(request, replyHandler: replyHandler)
            
        case DebugAdapter.RestartFrameRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.RestartFrameRequest.self, from: data)
            restartFrame(request, replyHandler: replyHandler)
            
        case DebugAdapter.ReverseContinueRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.ReverseContinueRequest.self, from: data)
            reverseContinue(request, replyHandler: replyHandler)
            
        case DebugAdapter.ScopesRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.ScopesRequest.self, from: data)
            scopes(request, replyHandler: replyHandler)
            
        case DebugAdapter.SetBreakpointsRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.SetBreakpointsRequest.self, from: data)
            setBreakpoints(request, replyHandler: replyHandler)
            
        case DebugAdapter.SetDataBreakpointsRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.SetDataBreakpointsRequest.self, from: data)
            setDataBreakpoints(request, replyHandler: replyHandler)

        case DebugAdapter.SetExceptionBreakpointsRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.SetExceptionBreakpointsRequest.self, from: data)
            setExceptionBreakpoints(request, replyHandler: replyHandler)

        case DebugAdapter.SetExpressionRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.SetExpressionRequest.self, from: data)
            setExpression(request, replyHandler: replyHandler)

        case DebugAdapter.SetFunctionBreakpointsRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.SetFunctionBreakpointsRequest.self, from: data)
            setFunctionBreakpoints(request, replyHandler: replyHandler)
            
        case DebugAdapter.SetInstructionBreakpointsRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.SetInstructionBreakpointsRequest.self, from: data)
            setInstructionBreakpoints(request, replyHandler: replyHandler)

        case DebugAdapter.SetVariableRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.SetVariableRequest.self, from: data)
            setVariable(request, replyHandler: replyHandler)

        case DebugAdapter.SourceRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.SourceRequest.self, from: data)
            source(request, replyHandler: replyHandler)

        case DebugAdapter.StackTraceRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.StackTraceRequest.self, from: data)
            stackTrace(request, replyHandler: replyHandler)
            
        case DebugAdapter.StepBackRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.StepBackRequest.self, from: data)
            stepBack(request, replyHandler: replyHandler)

        case DebugAdapter.StepInRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.StepInRequest.self, from: data)
            stepIn(request, replyHandler: replyHandler)
            
        case DebugAdapter.StepInTargetsRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.StepInTargetsRequest.self, from: data)
            stepInTargets(request, replyHandler: replyHandler)

        case DebugAdapter.StepOutRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.StepOutRequest.self, from: data)
            stepOut(request, replyHandler: replyHandler)
            
        case DebugAdapter.TerminateRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.TerminateRequest.self, from: data)
            terminate(request, replyHandler: replyHandler)
            
        case DebugAdapter.TerminateThreadsRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.TerminateThreadsRequest.self, from: data)
            terminateThreads(request, replyHandler: replyHandler)

        case DebugAdapter.ThreadsRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.ThreadsRequest.self, from: data)
            threads(request, replyHandler: replyHandler)

        case DebugAdapter.VariablesRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.VariablesRequest.self, from: data)
            variables(request, replyHandler: replyHandler)
            
        case DebugAdapter.WriteMemoryRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.WriteMemoryRequest.self, from: data)
            writeMemory(request, replyHandler: replyHandler)
            
        default:
            throw DebugAdapterConnection.MessageError.unsupportedRequest(command)
        }
    }
    
    func attach(_ request: DebugAdapter.AttachRequest<AttachParameters>, replyHandler: @escaping (Result<(), Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func breakpointLocations(_ request: DebugAdapter.BreakpointLocationsRequest, replyHandler: @escaping (Result<DebugAdapter.BreakpointLocationsRequest.Result, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func completions(_ request: DebugAdapter.CompletionsRequest, replyHandler: @escaping (Result<DebugAdapter.CompletionsRequest.Result, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func configurationDone(_ request: DebugAdapter.ConfigurationDoneRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func `continue`(_ request: DebugAdapter.ContinueRequest, replyHandler: @escaping (Result<DebugAdapter.ContinueRequest.Result, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func dataBreakpointInfo(_ request: DebugAdapter.DataBreakpointInfoRequest, replyHandler: @escaping (Result<DebugAdapter.DataBreakpointInfoRequest.Result, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func disassemble(_ request: DebugAdapter.DisassembleRequest, replyHandler: @escaping (Result<DebugAdapter.DisassembleRequest.Result?, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func disconnect(_ request: DebugAdapter.DisconnectRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func evaluate(_ request: DebugAdapter.EvaluateRequest, replyHandler: @escaping (Result<DebugAdapter.EvaluateRequest.Result, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func exceptionInfo(_ request: DebugAdapter.ExceptionInfoRequest, replyHandler: @escaping (Result<DebugAdapter.ExceptionInfoRequest.Result, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func goto(_ request: DebugAdapter.GotoRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func gotoTargets(_ request: DebugAdapter.GotoTargetsRequest, replyHandler: @escaping (Result<DebugAdapter.GotoTargetsRequest.Result, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func initialize(_ request: DebugAdapter.InitializeRequest, replyHandler: @escaping (Result<DebugAdapter.InitializeRequest.Result?, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func launch(_ request: DebugAdapter.LaunchRequest<LaunchParameters>, replyHandler: @escaping (Result<(), Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func loadedSources(_ request: DebugAdapter.LoadedSourcesRequest, replyHandler: @escaping (Result<DebugAdapter.LoadedSourcesRequest.Result, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func next(_ request: DebugAdapter.NextRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func pause(_ request: DebugAdapter.PauseRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func readMemory(_ request: DebugAdapter.ReadMemoryRequest, replyHandler: @escaping (Result<DebugAdapter.ReadMemoryRequest.Result?, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func restart(_ request: DebugAdapter.RestartRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func restartFrame(_ request: DebugAdapter.RestartFrameRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func reverseContinue(_ request: DebugAdapter.ReverseContinueRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func scopes(_ request: DebugAdapter.ScopesRequest, replyHandler: @escaping (Result<DebugAdapter.ScopesRequest.Result, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func setBreakpoints(_ request: DebugAdapter.SetBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetBreakpointsRequest.Result, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func setDataBreakpoints(_ request: DebugAdapter.SetDataBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetDataBreakpointsRequest.Result, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func setExceptionBreakpoints(_ request: DebugAdapter.SetExceptionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetExceptionBreakpointsRequest.Result?, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func setExpression(_ request: DebugAdapter.SetExpressionRequest, replyHandler: @escaping (Result<DebugAdapter.SetExpressionRequest.Result, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func setFunctionBreakpoints(_ request: DebugAdapter.SetFunctionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetFunctionBreakpointsRequest.Result?, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func setInstructionBreakpoints(_ request: DebugAdapter.SetInstructionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetInstructionBreakpointsRequest.Result, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func setVariable(_ request: DebugAdapter.SetVariableRequest, replyHandler: @escaping (Result<DebugAdapter.SetVariableRequest.Result, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func source(_ request: DebugAdapter.SourceRequest, replyHandler: @escaping (Result<DebugAdapter.SourceRequest.Result, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func stackTrace(_ request: DebugAdapter.StackTraceRequest, replyHandler: @escaping (Result<DebugAdapter.StackTraceRequest.Result, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func stepBack(_ request: DebugAdapter.StepBackRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func stepIn(_ request: DebugAdapter.StepInRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func stepInTargets(_ request: DebugAdapter.StepInTargetsRequest, replyHandler: @escaping (Result<DebugAdapter.StepInTargetsRequest.Result, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func stepOut(_ request: DebugAdapter.StepOutRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func terminate(_ request: DebugAdapter.TerminateRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func terminateThreads(_ request: DebugAdapter.TerminateThreadsRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func threads(_ request: DebugAdapter.ThreadsRequest, replyHandler: @escaping (Result<DebugAdapter.ThreadsRequest.Result, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func variables(_ request: DebugAdapter.VariablesRequest, replyHandler: @escaping (Result<DebugAdapter.VariablesRequest.Result, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
    
    func writeMemory(_ request: DebugAdapter.WriteMemoryRequest, replyHandler: @escaping (Result<DebugAdapter.WriteMemoryRequest.Result?, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
}

public extension DebugAdapterClientRequestHandler {
    /// Handlers may override this method to perform special handling of standard or custom requests, and may invoke
    /// `performDefaultHanding(forCommand:data:token:reply:)` to delegate to the default implementation for requests not handled.
    func handleRequest(forCommand command: String, data: Data, connection: DebugAdapterConnection) throws {
        try performDefaultHandling(forCommand: command, data: data, connection: connection)
    }
    
    /// Performs the default handling for supported request types.
    /// Request types that are not supported will return with DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command).
    func performDefaultHandling(forCommand command: String, data: Data, connection: DebugAdapterConnection) throws {
        switch command {
        case DebugAdapter.RunInTerminalRequest.command:
            let (request, replyHandler) = try connection.decodeForReply(DebugAdapter.RunInTerminalRequest.self, from: data)
            runInTerminal(request, replyHandler: replyHandler)
            
        default:
            throw DebugAdapterConnection.MessageError.unsupportedRequest(command)
        }
    }
    
    func runInTerminal(_ request: DebugAdapter.RunInTerminalRequest, replyHandler: @escaping (Result<DebugAdapter.RunInTerminalRequest.Result, Error>) -> ()) {
        replyHandler(.failure(DebugAdapterConnection.MessageError.unsupportedRequest(type(of: request).command)))
    }
}
