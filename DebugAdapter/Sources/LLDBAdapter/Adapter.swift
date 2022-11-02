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
        listener.startListening(in: debugger, eventClass: LLDBThread.broadcasterClassName, mask: UInt32.max)
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
            
            let target: LLDBTarget?
            if let pid = try body.getIfPresent(Int.self, for: "pid") {
                // Process Identifier
                options.processIdentifier = pid_t(pid)
                target = try debugger.findTarget(withProcessIdentifier: pid_t(pid))
            }
            else if let attachPath = try body.getIfPresent(String.self, for: "program") {
                // Process Path
                let attachURL = URL(fileURLWithPath: attachPath)
                options.executableURL = attachURL
                target = try debugger.createTarget(with: attachURL, architecture: nil)
            }
            else {
                replyHandler(.failure(AdapterError.invalidArguments(reason: "No pid or process name specified for `attach` request.")))
                return
            }
            
            self.target = target
            
            configuration = .attach(options)
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
    
    private var attachWaitProcess: LLDBProcess?
    
    private func startSession() {
        do {
            guard let configuration = configuration, let target = target else {
                throw AdapterError.invalidArguments(reason: "No `launch` or `attach` request was sent before `configurationDone`.")
            }
            
            switch configuration {
                case .launch(let options):
                    let process = try target.launch(with: options)
                    
                    sendProcessEvent(process, startMethod: .launch)
                    
                    if options.stopAtEntry {
                        notifyProcessStopped()
                    }
                    
                case .attach(let options):
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
    
    private func sendProcessEvent(_ process: LLDBProcess, startMethod: DebugAdapter.ProcessEvent.StartMethod) {
        // Process event
        let processIdentifier = process.processIdentifier
        let name = process.name ?? "(unknown)"
        
        var event = DebugAdapter.ProcessEvent(name: name)
        event.startMethod = startMethod
        event.isLocalProcess = true
        event.systemProcessId = Int(processIdentifier)
        connection.send(event)
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
        let eventType = breakpointEvent.eventType
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
            
            if let condition = sourceBreakpoint.condition {
                bp.condition = condition
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
            
            if let condition = functionBreakpoint.condition {
                bp.condition = condition
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
                if let process = attachWaitProcess {
                    // Attached
                    sendProcessEvent(process, startMethod: .attach)
                    
                    switch configuration {
                    case .attach(let options):
                        if options.stopAtEntry {
                            notifyProcessStopped()
                        }
                    default:
                        break
                    }
                    
                    attachWaitProcess = nil
                }
                
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
        var hitBreakpointIDs: [Int] = []
        
        if let stoppedThread = stoppedThread {
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
        event.threadId = Int(truncatingIfNeeded: stoppedThread?.threadID ?? 0)
        if hitBreakpointIDs.count > 0 {
            event.hitBreakpointIds = hitBreakpointIDs
        }
        
        connection.send(event)
    }
    
    private func beforeContinue() {
        variables.removeAll()
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
            // Terminate debuggee if needed
            let shouldTerminate = request.terminateDebuggee ?? terminateOnDisconnect
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
        if let attachWaitProcess = attachWaitProcess {
            do {
                try attachWaitProcess.stop()
            }
            catch {
                
            }
            self.attachWaitProcess = nil
        }
        
        // Clear all breakpoint callbacks
        LLDBBreakpoint.clearAllCallbacks()
        
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
            
            beforeContinue()
            
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
            
            beforeContinue()
            
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
            
            beforeContinue()
            
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
            
            beforeContinue()
            
            try thread.stepOut()
            
            replyHandler(.success(()))
        }
        catch {
            replyHandler(.failure(error))
        }
    }
    
    // MARK: - Threads
    
    enum VariableContainer {
        case stackFrame(LLDBFrame)
        case locals(LLDBFrame)
        case statics(LLDBFrame)
        case globals(LLDBFrame)
        case registers(LLDBFrame)
        case value(LLDBValue)
    }
    var variables = ReferenceTree<Int, VariableContainer>(startingAt: 1000)
    
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
        
        let frames = thread.frames.enumerated().map { (idx, frame) in
            let key = "[\(thread.indexID), \(idx)]"
            let ref = variables.insert(parent: nil, key: key, value: .stackFrame(frame))
            
            var debugFrame = DebugAdapter.StackFrame(id: ref)
            
            debugFrame.name = frame.displayFunctionName ?? "\(String(format: "%02X", frame.pcAddress))"
            
            let lineEntry = frame.lineEntry
            if let fileURL = lineEntry.fileSpec.fileURL {
                var source = DebugAdapter.Source()
                source.name = fileURL.lastPathComponent
                source.path = fileURL.path
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
            case .stackFrame(let frame):
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
                replyHandler(.failure(AdapterError.invalidArguments(reason: "Invalid stack frame ID \(frameID).")))
                return
        }
    }
    
    func variables(_ request: DebugAdapter.VariablesRequest, replyHandler: @escaping (Result<DebugAdapter.VariablesRequest.Result, Error>) -> ()) {
        let ref = request.variablesReference
        
        if let container = variables[ref] {
            switch container {
                case .locals(let frame):
                    let values = frame.variables(withArguments: false, locals: true, statics: false, inScopeOnly: true)
                    let variables = self.variables(for: values.values, containerRef: ref, uniquing: true)
                    replyHandler(.success(.init(variables: variables)))
                    
                case .statics(let frame):
                    let values = frame.variables(withArguments: false, locals: false, statics: true, inScopeOnly: true)
                    let variables = self.variables(for: values.values, types: [.variableStatic], containerRef: ref, uniquing: false)
                    replyHandler(.success(.init(variables: variables)))
                    
                case .globals(let frame):
                    let values = frame.variables(withArguments: false, locals: false, statics: true, inScopeOnly: true)
                    let variables = self.variables(for: values.values, types: [.variableGlobal], containerRef: ref, uniquing: false)
                    replyHandler(.success(.init(variables: variables)))
                    
                case .registers(let frame):
                    let values = frame.registers
                    let variables = self.variables(for: values.values, containerRef: ref, uniquing: false)
                    replyHandler(.success(.init(variables: variables)))
                    
                case .value(let value):
                    let variables = self.variables(for: value.children, containerRef: ref, uniquing: false)
                    replyHandler(.success(.init(variables: variables)))
                
                case .stackFrame(_):
                    replyHandler(.success(.init(variables: [])))
            }
        }
        else {
            replyHandler(.failure(AdapterError.invalidArguments(reason: "Invalid variables reference: \(ref).")))
        }
    }
    
    private func variables(for values: [LLDBValue], types: Set<LLDBValueType>? = nil, containerRef: Int, uniquing: Bool) -> [DebugAdapter.Variable] {
        var variables: [DebugAdapter.Variable] = []
        var variablesIndexesByName: [String: Int] = [:]
        
        for item in values {
            if let types = types, !types.contains(item.valueType) {
                continue
            }
            
            let name = item.name
            let value = displayString(forValue: item)
            
            var variable = DebugAdapter.Variable(name: name, value: value)
            
            variable.type = item.displayTypeName
            variable.variablesReference = variableReference(for: item, key: name, parent: containerRef)
            
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
    
    private func variableReference(for value: LLDBValue, key: String, parent: Int?) -> Int? {
        if value.childCount > 0 && !value.isSynthetic {
            return variables.insert(parent: parent, key: key, value: .value(value))
        }
        else {
            return nil
        }
    }
    
    private func displayString(forValue value: LLDBValue) -> String {
        return value.summary ?? value.stringValue ?? "<unavailable>"
    }
    
    func exceptionInfo(_ request: DebugAdapter.ExceptionInfoRequest, replyHandler: @escaping (Result<DebugAdapter.ExceptionInfoRequest.Result, Error>) -> ()) {
        replyHandler(.failure(AdapterError.invalidArguments(reason: "Not yet implemented.")))
    }
    
    func completions(_ request: DebugAdapter.CompletionsRequest, replyHandler: @escaping (Result<DebugAdapter.CompletionsRequest.Result, Error>) -> ()) {
        do {
            guard let debugger = debugger else {
                throw AdapterError.invalidArguments(reason: "No debuggee is running.")
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
            let strings = interpreter.handleCompletions(text, cursorPosition: UInt(cursorPosition), matchStart: 0, maxResults: 0)
            
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
            var frame: LLDBFrame?
            if let frameID = request.frameId {
                let container = variables[frameID]
                switch container {
                case .stackFrame(let f):
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
    
    private func executionContext(for frame: LLDBFrame?) throws -> LLDBExecutionContext {
        if let frame = frame {
            return LLDBExecutionContext(from: frame)
        }
        else {
            guard let target = target else {
                throw AdapterError.invalidArguments(reason: "No debuggee is running.")
            }
            
            if let process = target.process, let thread = process.selectedThread {
                return LLDBExecutionContext(from: thread)
            }
            else {
                return LLDBExecutionContext(from: target)
            }
        }
    }
    
    private func executeCommand(_ expression: String, frame: LLDBFrame?) throws -> DebugAdapter.EvaluateRequest.Result {
        guard let debugger = debugger else {
            throw AdapterError.invalidArguments(reason: "No debuggee is running.")
        }
        
        let interpreter = debugger.commandInterpreter
        let context = try executionContext(for: frame)
        
        let result = try interpreter.handleCommand(expression, context: context, addToHistory: false)
        let output = result.output ?? ""
        
        return .init(result: output)
    }
    
    private func evaluateExpression(_ expression: String, frame: LLDBFrame?) throws -> DebugAdapter.EvaluateRequest.Result {
        guard let target = target else {
            throw AdapterError.invalidArguments(reason: "No debuggee is running.")
        }
        
        let result: LLDBValue
        if let frame = frame {
            result = try frame.evaluateExpression(expression)
        }
        else {
            result = try target.evaluateExpression(expression)
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
            
            let child: LLDBValue?
            switch container {
            case .value(let value):
                child = value.childMember(withName: name)
            case .locals(let frame), .globals(let frame), .statics(let frame):
                child = frame.findVariable(name)
            default:
                child = nil
            }
            
            if let child = child {
                let value = request.value
                try child.setValue(from: value)
                
                let summary = displayString(forValue: child)
                
                var result = DebugAdapter.SetVariableRequest.Result(value: summary)
                result.type = child.displayTypeName
                result.variablesReference = variableReference(for: child, key: child.name, parent: ref)
                
                replyHandler(.success(result))
            }
            else {
                throw AdapterError.invalidArguments(reason: "Unable to set variable value \"\(name)\".")
            }
        }
        catch {
            replyHandler(.failure(error))
        }
    }
}
