import CxxLLDB

public struct ExecutionContext: Sendable {
    nonisolated(unsafe) let lldbExecutionContext: lldb.SBExecutionContext
    
    init(_ lldbExecutionContext: lldb.SBExecutionContext) {
        self.lldbExecutionContext = lldbExecutionContext
    }
    
    public init(from target: Target) {
        self.lldbExecutionContext = lldb.SBExecutionContext(target.lldbTarget)
    }
    
    public init(from process: Process) {
        self.lldbExecutionContext = lldb.SBExecutionContext(process.lldbProcess)
    }
    
    public init(from thread: Thread) {
        self.lldbExecutionContext = lldb.SBExecutionContext(thread.lldbThread)
    }
    
    public init(from frame: Frame) {
        self.lldbExecutionContext = lldb.SBExecutionContext(frame.lldbFrame)
    }
    
    public var target: Target? {
        return Target(lldbExecutionContext.GetTarget())
    }
    
    public var process: Process? {
        return Process(lldbExecutionContext.GetProcess())
    }
    
    public var thread: Thread? {
        return Thread(lldbExecutionContext.GetThread())
    }
    
    public var frame: Frame? {
        return Frame(lldbExecutionContext.GetFrame())
    }
}
