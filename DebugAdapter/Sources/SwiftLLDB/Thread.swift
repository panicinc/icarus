import CxxLLDB

public struct Thread: Equatable, Identifiable {
    let lldbThread: lldb.SBThread
    
    init(_ lldbThread: lldb.SBThread) {
        self.lldbThread = lldbThread
    }
    
    public static func == (lhs: Thread, rhs: Thread) -> Bool {
        return lhs.lldbThread == rhs.lldbThread
    }
    
    public static let broadcasterClassName = String(cString: lldb.SBThread.GetBroadcasterClassName())
    
    public var id: Int {
        Int(lldbThread.GetThreadID())
    }
    
    public var indexID: Int {
        Int(lldbThread.GetIndexID())
    }
    
    public var name: String? {
        if let str = lldbThread.GetName() {
            return String(cString: str)
        }
        else {
            return nil
        }
    }
    
    public var process: Process? {
        var lldbThread = lldbThread
        let lldbProcess = lldbThread.GetProcess();
        if lldbProcess.IsValid() {
            return Process(lldbProcess)
        }
        else {
            return nil
        }
    }
    
    public var queueName: String? {
        if let str = lldbThread.GetQueueName() {
            return String(cString: str)
        }
        else {
            return nil
        }
    }
    
    public var queue: Queue? {
        let lldbQueue = lldbThread.GetQueue();
        if lldbQueue.IsValid() {
            return Queue(lldbQueue)
        }
        else {
            return nil
        }
    }
    
    public var isSuspended: Bool {
        var lldbThread = lldbThread
        return lldbThread.IsSuspended()
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
    
    public var stopReasonDataCount: Int {
        var lldbThread = lldbThread
        return Int(lldbThread.GetStopReasonDataCount())
    }
    
    public func stopReasonData(at index: Int) -> UInt64 {
        var lldbThread = lldbThread
        return lldbThread.GetStopReasonDataAtIndex(UInt32(index))
    }
    
    public var frameCount: Int {
        var lldbThread = lldbThread
        return Int(lldbThread.GetNumFrames())
    }
    
    public func frame(at index: Int) -> Frame {
        var lldbThread = lldbThread
        return Frame(lldbThread.GetFrameAtIndex(UInt32(index)))
    }
    
    public var frames: [Frame] {
        var lldbThread = lldbThread
        let count = lldbThread.GetNumFrames()
        return (0 ..< count).map { Frame(lldbThread.GetFrameAtIndex($0)) }
    }
    
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
    public func selectFrame(at index: Int) -> Frame {
        var lldbThread = lldbThread
        return Frame(lldbThread.SetSelectedFrame(UInt32(index)))
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
    
    public var currentException: Value? {
        var lldbThread = lldbThread
        var lldbValue = lldbThread.GetCurrentException()
        if lldbValue.IsValid() {
            return Value(lldbValue)
        }
        else {
            return nil
        }
    }
    
    public var isSafeToCallFunctions: Bool {
        var lldbThread = lldbThread
        return lldbThread.SafeToCallFunctions()
    }
}

public struct ThreadEvent {
    let lldbEvent: lldb.SBEvent
    
    init(_ lldbEvent: lldb.SBEvent) {
        self.lldbEvent = lldbEvent
    }
    
    public init?(_ event: Event) {
        let lldbEvent = event.lldbEvent
        if lldb.SBThread.EventIsThreadEvent(lldbEvent) {
            self.init(lldbEvent)
        }
        else {
            return nil
        }
    }
    
    public var thread: Thread {
        Thread(lldb.SBThread.GetThreadFromEvent(lldbEvent))
    }
}
