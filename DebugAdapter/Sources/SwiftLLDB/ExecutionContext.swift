import CxxLLDB

public struct ExecutionContext {
    let lldbExecutionContext: lldb.SBExecutionContext
    
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
        let lldbTarget = lldbExecutionContext.GetTarget()
        if lldbTarget.IsValid() {
            return Target(lldbTarget)
        }
        else {
            return nil
        }
    }
    
    public var process: Process? {
        let lldbProcess = lldbExecutionContext.GetProcess()
        if lldbProcess.IsValid() {
            return Process(lldbProcess)
        }
        else {
            return nil
        }
    }
    
    public var thread: Thread? {
        let lldbThread = lldbExecutionContext.GetThread()
        if lldbThread.IsValid() {
            return Thread(lldbThread)
        }
        else {
            return nil
        }
    }
    
    public var frame: Frame? {
        let lldbFrame = lldbExecutionContext.GetFrame()
        if lldbFrame.IsValid() {
            return Frame(lldbFrame)
        }
        else {
            return nil
        }
    }
}
