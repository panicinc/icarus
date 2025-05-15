import CxxLLDB

public enum Event: Sendable {
    case breakpoint(BreakpointEvent)
    case process(ProcessEvent)
    case target(TargetEvent)
    case thread(ThreadEvent)
}

extension Event {
    init?(_ lldbEvent: lldb.SBEvent) {
        if lldb.SBBreakpoint.EventIsBreakpointEvent(lldbEvent) {
            self = .breakpoint(BreakpointEvent(lldbEvent))
        }
        else if lldb.SBProcess.EventIsProcessEvent(lldbEvent) {
            self = .process(ProcessEvent(lldbEvent))
        }
        else if lldb.SBTarget.EventIsTargetEvent(lldbEvent) {
            self = .target(TargetEvent(lldbEvent))
        }
        else if lldb.SBThread.EventIsThreadEvent(lldbEvent) {
            self = .thread(ThreadEvent(lldbEvent))
        }
        else {
            return nil
        }
    }
}
