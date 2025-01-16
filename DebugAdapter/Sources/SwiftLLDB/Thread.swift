import CxxLLDB

public struct Thread: Sendable {
    let lldbThread: lldb.SBThread
    
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
    
    public var process: Process? {
        var lldbThread = lldbThread
        return Process(lldbThread.GetProcess())
    }
    
    public var queueName: String? {
        return String(optionalCString: lldbThread.GetQueueName())
    }
    
    public var queue: Queue? {
        return Queue(lldbThread.GetQueue())
    }
    
    public var displayName: String {
        if let name {
            return name
        }
        else if let queueName, let queue {
            let queueKindLabel: String
            switch queue.kind {
            case .serial:
                queueKindLabel = " (serial)"
            case .concurrent:
                queueKindLabel = " (concurrent)"
            default:
                queueKindLabel = ""
            }
            return "Thread \(indexID) Queue: \(queueName)\(queueKindLabel)"
        }
        else {
            return "Thread \(indexID)"
        }
    }
}

extension Thread {
    public var isSuspended: Bool {
        var lldbThread = lldbThread
        return lldbThread.IsSuspended()
    }
    
    public var currentException: Value? {
        var lldbThread = lldbThread
        return Value(lldbThread.GetCurrentException())
    }
    
    public var isSafeToCallFunctions: Bool {
        var lldbThread = lldbThread
        return lldbThread.SafeToCallFunctions()
    }
    
    public var isStopped: Bool {
        var lldbThread = lldbThread
        return lldbThread.IsStopped()
    }
    
    public struct StopReason: RawRepresentable, Hashable {
        public static let invalid = Self(lldb.eStopReasonInvalid)
        public static let none = Self(lldb.eStopReasonNone)
        public static let trace = Self(lldb.eStopReasonTrace)
        public static let breakpoint = Self(lldb.eStopReasonBreakpoint)
        public static let watchpoint = Self(lldb.eStopReasonWatchpoint)
        public static let signal = Self(lldb.eStopReasonSignal)
        public static let exception = Self(lldb.eStopReasonException)
        public static let exec = Self(lldb.eStopReasonExec)
        public static let planComplete = Self(lldb.eStopReasonPlanComplete)
        public static let threadExiting = Self(lldb.eStopReasonThreadExiting)
        public static let instrumentation = Self(lldb.eStopReasonInstrumentation)
        public static let processorTrace = Self(lldb.eStopReasonProcessorTrace)
        public static let fork = Self(lldb.eStopReasonFork)
        public static let vFork = Self(lldb.eStopReasonVFork)
        public static let vForkDone = Self(lldb.eStopReasonVForkDone)
        
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        init(_ lldbStopReason: lldb.StopReason) {
            self.rawValue = Int(lldbStopReason.rawValue)
        }
    }
    
    public var stopReason: StopReason {
        var lldbThread = lldbThread
        return StopReason(lldbThread.GetStopReason())
    }
    
    public struct StopReasonData: Sendable, RandomAccessCollection {
        let lldbThread: lldb.SBThread
        
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
        let lldbThread: lldb.SBThread
        
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
    public func selectFrame(at index: Int) -> Frame? {
        var lldbThread = lldbThread
        return Frame(lldbThread.SetSelectedFrame(UInt32(index)))
    }
}

public struct ThreadEvent: Sendable {
    let lldbEvent: lldb.SBEvent
    
    init(_ lldbEvent: lldb.SBEvent) {
        self.lldbEvent = lldbEvent
    }
    
    public var thread: Thread {
        return Thread(unsafe: lldb.SBThread.GetThreadFromEvent(lldbEvent))
    }
}
