import CxxLLDB

public struct Thread: Sendable {
    nonisolated(unsafe) let lldbThread: lldb.SBThread
    
    init?(_ lldbThread: lldb.SBThread) {
        guard lldbThread.IsValid() else {
            return nil
        }
        self.lldbThread = lldbThread
    }
    
    init(unsafe lldbThread: lldb.SBThread) {
        self.lldbThread = lldbThread
    }
}

extension Thread: Equatable {
    public static func == (lhs: Thread, rhs: Thread) -> Bool {
        return lhs.lldbThread == rhs.lldbThread
    }
}

extension Thread: Identifiable {
    public var id: Int {
        return Int(lldbThread.GetThreadID())
    }
}

extension Thread {
    public var indexID: Int {
        return Int(lldbThread.GetIndexID())
    }
    
    public var name: String? {
        return String(optionalCString: lldbThread.GetName())
    }
    
    public var displayName: String {
        if let name {
            return "\(name) (\(indexID))"
        }
        else {
            return "Thread \(indexID)"
        }
    }
    
    public var queueName: String? {
        return String(optionalCString: lldbThread.GetQueueName())
    }
    
    public var queue: Queue? {
        return Queue(lldbThread.GetQueue())
    }
    
    public var queueDisplayName: String? {
        guard let queueName, let queue else {
            return nil
        }
        
        let queueKindLabel: String
        switch queue.kind {
        case .serial:
            queueKindLabel = " (serial)"
        case .concurrent:
            queueKindLabel = " (concurrent)"
        default:
            queueKindLabel = ""
        }
        return "Queue: \(queueName)\(queueKindLabel)"
    }
    
    public var description: String? {
        var stream = lldb.SBStream()
        lldbThread.GetDescription(&stream)
        return String(optionalCString: stream.GetData())
    }
    
    public var process: Process {
        var lldbThread = lldbThread
        return Process(unsafe: lldbThread.GetProcess())
    }
}

extension Thread {
    public var isSuspended: Bool {
        var lldbThread = lldbThread
        return lldbThread.IsSuspended()
    }
    
    public var isStopped: Bool {
        var lldbThread = lldbThread
        return lldbThread.IsStopped()
    }
    
    public enum StopReason: Equatable {
        case trace
        case breakpoint([Int])
        case watchpoint(Int)
        case signal(Int)
        case exception
        case exec
        case planComplete
        case threadExiting
        case instrumentation
        case processorTrace
        case fork(Int)
        case vFork(Int)
        case vForkDone
    }
    
    public var stopReason: StopReason? {
        var lldbThread = lldbThread
        switch lldbThread.GetStopReason() {
        case lldb.eStopReasonInvalid,
            lldb.eStopReasonNone:
            return nil
        case lldb.eStopReasonTrace:
            return .trace
        case lldb.eStopReasonBreakpoint:
            let data = StopReasonData(lldbThread)
            return .breakpoint(stride(from: 0, to: data.count, by: 2).map({ Int(data[$0]) }))
        case lldb.eStopReasonWatchpoint:
            let data = StopReasonData(lldbThread)
            return .watchpoint(Int(data[0]))
        case lldb.eStopReasonSignal:
            let data = StopReasonData(lldbThread)
            return .signal(Int(data[0]))
        case lldb.eStopReasonException:
            return .exception
        case lldb.eStopReasonExec:
            return .exec
        case lldb.eStopReasonPlanComplete:
            return .planComplete
        case lldb.eStopReasonThreadExiting:
            return .threadExiting
        case lldb.eStopReasonInstrumentation:
            return .instrumentation
        case lldb.eStopReasonProcessorTrace:
            return .processorTrace
        case lldb.eStopReasonFork:
            let data = StopReasonData(lldbThread)
            return .fork(Int(data[0]))
        case lldb.eStopReasonVFork:
            let data = StopReasonData(lldbThread)
            return .vFork(Int(data[0]))
        case lldb.eStopReasonVForkDone:
            return .vForkDone
        default:
            return nil
        }
    }
    
    public var hasValidStopReason: Bool {
        var lldbThread = lldbThread
        switch lldbThread.GetStopReason() {
        case lldb.eStopReasonTrace,
            lldb.eStopReasonBreakpoint,
            lldb.eStopReasonWatchpoint,
            lldb.eStopReasonSignal,
            lldb.eStopReasonException,
            lldb.eStopReasonExec,
            lldb.eStopReasonPlanComplete,
            lldb.eStopReasonThreadExiting,
            lldb.eStopReasonInstrumentation,
            lldb.eStopReasonProcessorTrace,
            lldb.eStopReasonFork,
            lldb.eStopReasonVFork,
            lldb.eStopReasonVForkDone:
            return true
        default:
            return false
        }
    }
    
    public struct StopReasonData: Sendable, RandomAccessCollection {
        nonisolated(unsafe) let lldbThread: lldb.SBThread
        
        init(_ lldbThread: lldb.SBThread) {
            self.lldbThread = lldbThread
        }
        
        public var count: Int {
            var lldbThread = lldbThread
            return lldbThread.GetStopReasonDataCount()
        }
        
        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { count }
        
        public subscript(position: Int) -> UInt64 {
            var lldbThread = lldbThread
            return lldbThread.GetStopReasonDataAtIndex(UInt32(position))
        }
    }
    
    public var stopReasonData: StopReasonData { StopReasonData(lldbThread) }
    
    public var stopDescription: String? {
        var lldbThread = lldbThread
        return withUnsafeTemporaryAllocation(of: CChar.self, capacity: 1024) { buffer in
            if lldbThread.GetStopDescription(buffer.baseAddress!, buffer.count) > 0 {
                return String(cString: buffer.baseAddress!)
            }
            else {
                return nil
            }
        }
    }
    
    public var currentException: Value? {
        var lldbThread = lldbThread
        return Value(lldbThread.GetCurrentException())
    }
    
    public var currentExceptionBacktrace: Thread? {
        var lldbThread = lldbThread
        return Thread(lldbThread.GetCurrentExceptionBacktrace())
    }
    
    public var isSafeToCallFunctions: Bool {
        var lldbThread = lldbThread
        return lldbThread.SafeToCallFunctions()
    }
    
    public func suspend() throws {
        var lldbThread = lldbThread
        var error = lldb.SBError()
        lldbThread.Suspend(&error)
        try error.throwOnFail()
    }
    
    public func resume() throws {
        var lldbThread = lldbThread
        var error = lldb.SBError()
        lldbThread.Resume(&error)
        try error.throwOnFail()
    }
    
    public func stepOver() throws {
        var lldbThread = lldbThread
        var error = lldb.SBError()
        lldbThread.StepOver(lldb.eOnlyDuringStepping, &error)
        try error.throwOnFail()
    }
    
    public func stepOverInstruction() throws {
        var lldbThread = lldbThread
        var error = lldb.SBError()
        lldbThread.StepInstruction(true, &error)
        try error.throwOnFail()
    }
    
    public func stepInto() throws {
        var lldbThread = lldbThread
        lldbThread.StepInto(lldb.eOnlyDuringStepping)
    }
    
    public func stepIntoInstruction() throws {
        var lldbThread = lldbThread
        var error = lldb.SBError()
        lldbThread.StepInstruction(false, &error)
        try error.throwOnFail()
    }
    
    public func stepOut() throws {
        var lldbThread = lldbThread
        var error = lldb.SBError()
        lldbThread.StepOut(&error)
        try error.throwOnFail()
    }
}

extension Thread {
    public struct Frames: Sendable, RandomAccessCollection {
        nonisolated(unsafe) let lldbThread: lldb.SBThread
        
        init(_ lldbThread: lldb.SBThread) {
            self.lldbThread = lldbThread
        }
        
        public var count: Int {
            var lldbThread = lldbThread
            return Int(lldbThread.GetNumFrames())
        }
        
        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { count }
        
        public subscript(position: Int) -> Frame {
            var lldbThread = lldbThread
            return Frame(unsafe: lldbThread.GetFrameAtIndex(UInt32(position)))
        }
    }
    
    public var frames: Frames { Frames(lldbThread) }
    
    public var selectedFrame: Frame? {
        var lldbThread = lldbThread
        let lldbFrame = lldbThread.GetSelectedFrame()
        if lldbFrame.IsValid() {
            return Frame(lldbFrame)
        }
        else {
            return nil
        }
    }
    
    @discardableResult
    public func setSelectedFrame(at index: Int) -> Frame? {
        var lldbThread = lldbThread
        return Frame(lldbThread.SetSelectedFrame(UInt32(index)))
    }
}

public struct ThreadEvent: Sendable {
    nonisolated(unsafe) let lldbEvent: lldb.SBEvent
    
    init(_ lldbEvent: lldb.SBEvent) {
        self.lldbEvent = lldbEvent
    }
    
    public var thread: Thread {
        return Thread(unsafe: lldb.SBThread.GetThreadFromEvent(lldbEvent))
    }
}
