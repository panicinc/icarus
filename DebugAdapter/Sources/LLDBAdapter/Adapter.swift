import Foundation
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
    
    private func logOutput(_ message: String, category: DebugAdapter.OutputEvent.Category) {
        connection.send(DebugAdapter.OutputEvent(output: message, category: category))
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
    
    private enum ExceptionBreakpointFilter: String {
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
        capabilities.supportsFunctionBreakpoints = true
        capabilities.supportsConditionalBreakpoints = true
        capabilities.supportsSetVariable = true
        capabilities.supportTerminateDebuggee = true
        capabilities.supportsExceptionInfoRequest = true
        capabilities.supportsEvaluateForHovers = true
        capabilities.supportsReadMemoryRequest = true
        capabilities.supportsCompletionsRequest = true
        capabilities.supportsWriteMemoryRequest = true
        
        let breakpointFilters: [ExceptionBreakpointFilter] = [.swift, .cppThrow, .cppCatch, .objcThrow, .objcCatch]
        capabilities.exceptionBreakpointFilters = breakpointFilters.map { .init(filter: $0.rawValue, label: $0.name) }
        
        replyHandler(.success(capabilities))
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
        case launch(LLDBLaunchOptions)
        case attach(LLDBAttachOptions)
    }
    private(set) var configuration: Configuration?
    
    private var terminateOnDisconnect = false
    
    private var target: LLDBTarget?
    
    func launch(_ request: DebugAdapter.LaunchRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        do {
            guard let debugger = debugger else {
                throw AdapterError.invalidArguments(reason: "No `initialize` request was sent before `launch`.")
            }
            
            guard let body = request.body else {
                throw AdapterError.invalidArguments(reason: "Missing `launch` request body.")
            }
            
            let launchPath = try body.get(String.self, for: "program")
            let launchURL = URL(fileURLWithPath: launchPath)
            
            let options = LLDBLaunchOptions()
            
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
            else if let runInRosetta = try body.getIfPresent(Bool.self, for: "runInRosetta"), runInRosetta {
                architecture = .x86_64
            }
            
            if let stopAtEntry = try body.getIfPresent(Bool.self, for: "stopAtEntry"), stopAtEntry {
                options.stopAtEntry = stopAtEntry
            }
            
            let target = try debugger.createTarget(with: launchURL, architecture: architecture?.rawValue)
            self.target = target
            
            configuration = .launch(options)
            debugStartRequest = .launch(request, replyHandler)
            terminateOnDisconnect = true
            connection.send(DebugAdapter.InitializedEvent())
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func attach(_ request: DebugAdapter.AttachRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        do {
            guard let debugger = debugger else {
                throw AdapterError.invalidArguments(reason: "No `initialize` request was sent before `launch`.")
            }
            
            guard let body = request.body else {
                throw AdapterError.invalidArguments(reason: "Missing `attach` request body.")
            }
            
            let options = LLDBAttachOptions()
            options.waitForLaunch = try body.getIfPresent(Bool.self, for: "wait") ?? false
            configuration = .attach(options)
            
            let target: LLDBTarget?
            if let pid = try body.getIfPresent(Int.self, for: "pid") {
                // Process Identifier
                let options = LLDBAttachOptions()
                
                options.waitForLaunch = try body.getIfPresent(Bool.self, for: "wait") ?? false
                target = try debugger.findTarget(withProcessIdentifier: pid_t(pid))
            }
            else if let attachPath = try body.getIfPresent(String.self, for: "program") {
                // Process Path
                let attachURL = URL(fileURLWithPath: attachPath)
                target = try debugger.findTarget(with: attachURL, architecture: nil)
            }
            else {
                replyHandler(.failure(AdapterError.invalidArguments(reason: "No pid or process name specified for `attach` request.")))
                return
            }
            
            self.target = target
            
            debugStartRequest = .attach(request, replyHandler)
            terminateOnDisconnect = false
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
    
    private func startSession() {
        do {
            guard let configuration = configuration, let target = target else {
                throw AdapterError.invalidArguments(reason: "No `launch` or `attach` request was sent before `configurationDone`.")
            }
            
            let startMethod: DebugAdapter.ProcessEvent.StartMethod
            
            let process: LLDBProcess
            switch configuration {
                case .launch(let options):
                    startMethod = .launch
                    process = try target.launch(with: options)
                    
                    if options.stopAtEntry {
                        notifyProcessStopped()
                    }
                    
                case .attach(let options):
                    startMethod = .attach
                    process = try target.attach(with: options)
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
            
            // Process event
            let processIdentifier = process.processIdentifier
            let name = process.name ?? "(unknown)"
            
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
        }
    }
    
    private func handleDebuggerEvent(_ event: LLDBEvent) {
        if let breakpointEvent = event.toBreakpointEvent() {
            handleBreakpointEvent(event, breakpointEvent: breakpointEvent)
        }
        else if let processEvent = event.toProcessEvent() {
            handleProcessEvent(event, processEvent: processEvent)
        }
        else if let targetEvent = event.toTargetEvent() {
            handleTargetEvent(event, targetEvent: targetEvent)
        }
        else if let threadEvent = event.toThreadEvent() {
            handleThreadEvent(event, threadEvent: threadEvent)
        }
    }
    
    // MARK: - Breakpoints
    
    private(set) var sourceBreakpoints: [URL: [Int: DebugAdapter.SourceBreakpoint]] = [:]
    
    private func standardizedFileURL(forPath path: String, isDirectory: Bool) -> URL {
        var fileURL = URL(fileURLWithPath: path, isDirectory: isDirectory)
        fileURL.standardize()
        fileURL.standardizeVolumeInFileURL()
        return fileURL
    }
    
    private func handleBreakpointEvent(_ event: LLDBEvent, breakpointEvent: LLDBBreakpointEvent) {
        
    }
    
    func setBreakpoints(_ request: DebugAdapter.SetBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetBreakpointsRequest.Result, Error>) -> ()) {
        let source = request.source
        
        guard let path = source.path else {
            replyHandler(.failure(AdapterError.invalidArguments(reason: "Breakpoint source path is missing.")))
            return
        }
        
        guard let target = target else {
            replyHandler(.failure(AdapterError.invalidArguments(reason: "Not debugging a target.")))
            return
        }
        
        let fileURL = standardizedFileURL(forPath: path, isDirectory: false)
        
        // Create new breakpoints
        var breakpoints: [DebugAdapter.Breakpoint] = []
        var newBreakpoints: [Int: DebugAdapter.SourceBreakpoint] = [:]
        
        var previousBreakpoints = sourceBreakpoints[fileURL] ?? [:]
        
        for sourceBreakpoint in request.breakpoints ?? [] {
            let line = sourceBreakpoint.line
            let column = sourceBreakpoint.column
            
            let matchingBP = previousBreakpoints.first(where: { $0.value.line == line && $0.value.column == column })
            
            let bp: LLDBBreakpoint
            if let matchingBP, let breakpoint = target.findBreakpoint(byID: UInt32(truncatingIfNeeded: matchingBP.key)) {
                bp = breakpoint
                previousBreakpoints[matchingBP.key] = nil
            }
            else {
                bp = target.createBreakpoint(for: fileURL, line: line as NSNumber, column: column as? NSNumber, offset: nil, moveToNearestCode: true)
            }
            
            let id = Int(bp.breakpointID)
            
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
            _ = target.removeBreakpoint(withID: UInt32(truncatingIfNeeded: id))
        }
        
        sourceBreakpoints[fileURL] = newBreakpoints.count > 0 ? newBreakpoints : nil
        
        replyHandler(.success(.init(breakpoints: breakpoints)))
    }
    
    private(set) var functionBreakpoints: [Int: DebugAdapter.FunctionBreakpoint] = [:]
    
    func setFunctionBreakpoints(_ request: DebugAdapter.SetFunctionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetFunctionBreakpointsRequest.Result?, Error>) -> ()) {
        guard let target = target else {
            replyHandler(.failure(AdapterError.invalidArguments(reason: "Not debugging a target.")))
            return
        }
        
        // Create new breakpoints
        var breakpoints: [DebugAdapter.Breakpoint] = []
        var newFunctionBreakpoints: [Int: DebugAdapter.FunctionBreakpoint] = [:]
        
        var previousBreakpoints = functionBreakpoints
        
        for functionBreakpoint in request.breakpoints {
            let name = functionBreakpoint.name
            
            let matchingBP = previousBreakpoints.first(where: { $0.value.name == name })
            
            let bp: LLDBBreakpoint
            if let matchingBP, let breakpoint = target.findBreakpoint(byID: UInt32(truncatingIfNeeded: matchingBP.key)) {
                bp = breakpoint
                previousBreakpoints[matchingBP.key] = nil
            }
            else {
                bp = target.createBreakpoint(forName: name)
            }
            
            let id = Int(bp.breakpointID)
            
            var breakpoint = DebugAdapter.Breakpoint()
            breakpoint.id = id
            breakpoint.verified = false
            
            breakpoints.append(breakpoint)
            newFunctionBreakpoints[id] = functionBreakpoint
        }
        
        // Update active session
        for (id, _) in previousBreakpoints {
            _ = target.removeBreakpoint(withID: UInt32(truncatingIfNeeded: id))
        }
        
        functionBreakpoints = newFunctionBreakpoints
        
        replyHandler(.success(.init(breakpoints: breakpoints)))
    }
    
    private(set) var exceptionFilters: [Int: String] = [:]
    
    func setExceptionBreakpoints(_ request: DebugAdapter.SetExceptionBreakpointsRequest, replyHandler: @escaping (Result<DebugAdapter.SetExceptionBreakpointsRequest.Result?, Error>) -> ()) {
        guard let target = target else {
            replyHandler(.failure(AdapterError.invalidArguments(reason: "Not debugging a target.")))
            return
        }
        
        var newExceptionFilters: [Int: String] = [:]
        var breakpoints: [DebugAdapter.Breakpoint] = []
        
        var previousFilters = exceptionFilters
        
        if let filters = request.filters {
            for filterName in filters {
                let matchingBP = previousFilters.first(where: { $0.value == filterName })
                
                let bp: LLDBBreakpoint
                if let matchingBP, let breakpoint = target.findBreakpoint(byID: UInt32(truncatingIfNeeded: matchingBP.key)) {
                    bp = breakpoint
                    previousFilters[matchingBP.key] = nil
                }
                else if let filter = ExceptionBreakpointFilter(rawValue: filterName) {
                    switch filter {
                    case .swift:
                        bp = target.createBreakpointForException(in: .swift, onCatch: false, onThrow: true)
                    case .cppThrow:
                        bp = target.createBreakpointForException(in: .cPlusPlus, onCatch: false, onThrow: true)
                    case .cppCatch:
                        bp = target.createBreakpointForException(in: .cPlusPlus, onCatch: true, onThrow: false)
                    case .objcThrow:
                        bp = target.createBreakpointForException(in: .objectiveC, onCatch: false, onThrow: true)
                    case .objcCatch:
                        bp = target.createBreakpointForException(in: .objectiveC, onCatch: true, onThrow: false)
                    }
                }
                else {
                    replyHandler(.failure(AdapterError.invalidArguments(reason: "Unsupported exception filter: \(filterName).")))
                    return
                }
                
                let id = Int(bp.breakpointID)
                
                var breakpoint = DebugAdapter.Breakpoint()
                breakpoint.id = id
                breakpoint.verified = false
                
                breakpoints.append(breakpoint)
                newExceptionFilters[id] = filterName
            }
        }
        
        exceptionFilters = newExceptionFilters
        
        for (id, _) in previousFilters {
            _ = target.removeBreakpoint(withID: UInt32(truncatingIfNeeded: id))
        }
        
        replyHandler(.success(.init(breakpoints: breakpoints)))
    }
    
    // MARK: - Execution
    
    private func handleProcessEvent(_ event: LLDBEvent, processEvent: LLDBProcessEvent) {
        let process = processEvent.process
        let flags = event.flags
        
        if (flags & LLDBProcessEventFlagStateChanged) != 0 {
            let state = processEvent.processState
            switch state {
            case .running, .stepping:
                notifyProcessRunning()
            case .stopped:
                if !processEvent.isRestarted {
                    notifyProcessStopped()
                }
            case .crashed, .suspended:
                notifyProcessStopped()
            case .exited:
                let process = processEvent.process
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
        
        if (flags & LLDBProcessEventFlagSTDOUT) != 0 {
            while let chunk = process.readDataFromStandardOut(toLength: 1024),
                  let string = String(data: chunk, encoding: .ascii) {
                logOutput(string, category: .standardOut)
            }
        }
        
        if (flags & LLDBProcessEventFlagSTDERR) != 0 {
            while let chunk = process.readDataFromStandardError(toLength: 1024),
                  let string = String(data: chunk, encoding: .ascii) {
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
        var stoppedThread: LLDBThread?
        if let selectedThread = selectedThread {
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
        switch stoppedThread?.stopReason {
            case .breakpoint:
                reason = .breakpoint
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
        
        var event = DebugAdapter.StoppedEvent(reason: reason)
        event.allThreadsStopped = true
        event.threadId = Int(truncatingIfNeeded: stoppedThread?.threadID ?? 0)
        
        connection.send(event)
    }
    
    private func handleTargetEvent(_ event: LLDBEvent, targetEvent s: LLDBTargetEvent) {
        let flags = event.flags
        if (flags & LLDBTargetEventFlagModulesLoaded) != 0 {
            
        }
        else if (flags & LLDBTargetEventFlagSymbolsLoaded) != 0 {
            
        }
        else if (flags & LLDBTargetEventFlagModulesUnloaded) != 0 {
            
        }
    }
    
    private func handleThreadEvent(_ event: LLDBEvent, threadEvent: LLDBThreadEvent) {
        
    }
    
    func disconnect(_ request: DebugAdapter.DisconnectRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        if let process = target?.process {
            let shouldTerminate = request.terminateDebugee ?? terminateOnDisconnect
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
        
        configuration = nil
        replyHandler(.success(()))
    }
    
    func pause(_ request: DebugAdapter.PauseRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        do {
            guard let target = target, let process = target.process else {
                throw AdapterError.invalidArguments(reason: "No debuggee is running.")
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
            guard let target = target, let process = target.process else {
                throw AdapterError.invalidArguments(reason: "No debuggee is running.")
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
    
    func next(_ request: DebugAdapter.NextRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        do {
            guard let target = target, let process = target.process else {
                throw AdapterError.invalidArguments(reason: "No debuggee is running.")
            }
            
            let threadID = request.threadId
            guard let thread = process.thread(withID: UInt64(threadID)) else {
                throw AdapterError.invalidArguments(reason: "Unknown thread \(threadID).")
            }
            
            try thread.stepOver()
            
            replyHandler(.success(()))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func stepIn(_ request: DebugAdapter.StepInRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        do {
            guard let target = target, let process = target.process else {
                throw AdapterError.invalidArguments(reason: "No debuggee is running.")
            }
            
            let threadID = request.threadId
            guard let thread = process.thread(withID: UInt64(threadID)) else {
                throw AdapterError.invalidArguments(reason: "Unknown thread \(threadID).")
            }
            
            thread.stepInto()
            
            replyHandler(.success(()))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    func stepOut(_ request: DebugAdapter.StepOutRequest, replyHandler: @escaping (Result<(), Error>) -> ()) {
        do {
            guard let target = target, let process = target.process else {
                throw AdapterError.invalidArguments(reason: "No debuggee is running.")
            }
            
            let threadID = request.threadId
            guard let thread = process.thread(withID: UInt64(threadID)) else {
                throw AdapterError.invalidArguments(reason: "Unknown thread \(threadID).")
            }
            
            try thread.stepOut()
            
            replyHandler(.success(()))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    // MARK: - Threads
    
    func threads(_ request: DebugAdapter.ThreadsRequest, replyHandler: @escaping (Result<DebugAdapter.ThreadsRequest.Result, Error>) -> ()) {
        guard let target = target, let process = target.process else {
            replyHandler(.failure(AdapterError.invalidArguments(reason: "No debuggee is running.")))
            return
        }
        
        let threads = process.threads.map { thread in
            return DebugAdapter.Thread(id: Int(truncatingIfNeeded: thread.threadID), name: thread.name ?? "Thread \(thread.indexID)")
        }
        
        replyHandler(.success(.init(threads: threads)))
    }
    
    func stackTrace(_ request: DebugAdapter.StackTraceRequest, replyHandler: @escaping (Result<DebugAdapter.StackTraceRequest.Result, Error>) -> ()) {
        guard let target = target, let process = target.process else {
            replyHandler(.failure(AdapterError.invalidArguments(reason: "No debuggee is running.")))
            return
        }
        
        let threadID = request.threadId
        guard let thread = process.thread(withID: UInt64(threadID)) else {
            replyHandler(.failure(AdapterError.invalidArguments(reason: "Invalid thread ID \(threadID).")))
            return
        }
        
        let frames = thread.frames.map { frame in
            var debugFrame = DebugAdapter.StackFrame(id: Int(frame.frameID))
            
            debugFrame.name = frame.displayFunctionName ?? "\(String(format: "%02X", frame.pcAddress))"
            
            if let fileURL = frame.fileURL {
                var source = DebugAdapter.Source()
                source.name = fileURL.lastPathComponent
                source.path = fileURL.path
                debugFrame.source = source
                
                debugFrame.line = Int(frame.line)
                debugFrame.column = Int(frame.column)
            }
            else {
                debugFrame.presentationHint = .subtle
            }
            
            return debugFrame
        }
        
        replyHandler(.success(.init(stackFrames: frames)))
    }
    
    func scopes(_ request: DebugAdapter.ScopesRequest, replyHandler: @escaping (Result<DebugAdapter.ScopesRequest.Result, Error>) -> ()) {
        replyHandler(.success(.init(scopes: [])))
    }
    
    func exceptionInfo(_ request: DebugAdapter.ExceptionInfoRequest, replyHandler: @escaping (Result<DebugAdapter.ExceptionInfoRequest.Result, Error>) -> ()) {
        replyHandler(.failure(AdapterError.invalidArguments(reason: "No exception has occurred.")))
    }
    
    func variables(_ request: DebugAdapter.VariablesRequest, replyHandler: @escaping (Result<DebugAdapter.VariablesRequest.Result, Error>) -> ()) {
        replyHandler(.success(.init(variables: [])))
    }
    
    func evaluate(_ request: DebugAdapter.EvaluateRequest, replyHandler: @escaping (Result<DebugAdapter.EvaluateRequest.Result, Error>) -> ()) {
        replyHandler(.failure(AdapterError.invalidArguments(reason: "Not yet implemented.")))
    }
    
    func completions(_ request: DebugAdapter.CompletionsRequest, replyHandler: @escaping (Result<DebugAdapter.CompletionsRequest.Result, Error>) -> ()) {
        replyHandler(.failure(AdapterError.invalidArguments(reason: "Not yet implemented.")))
    }
}
