import CxxLLDB

public struct Event {
    let lldbEvent: lldb.SBEvent
    
    init(_ lldbEvent: lldb.SBEvent) {
        self.lldbEvent = lldbEvent
    }
    
    public var flags: Int {
        Int(lldbEvent.GetType())
    }
}
