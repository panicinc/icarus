import Foundation
import CxxLLDB

public final class Listener {
    public let name: String
    public let eventHandler: (Event) -> ()
    
    private var lldbListener = lldb.SBListener()
    
    private var thread: Foundation.Thread?
    
    public init(name: String, eventHandler: @escaping (Event) -> ()) {
        self.name = name
        self.eventHandler = eventHandler
    }
    
    @discardableResult
    public func startListening(in debugger: Debugger, eventClass: String, mask: UInt32) -> UInt32 {
        return eventClass.withCString { eventClassStr in
            var lldbDebugger = debugger.lldbDebugger
            return lldbListener.StartListeningForEventClass(&lldbDebugger, eventClassStr, mask)
        }
    }
    
    @discardableResult
    public func stopListening(in debugger: Debugger, eventClass: String, mask: UInt32) -> Bool {
        var lldbDebugger = debugger.lldbDebugger
        return lldbListener.StopListeningForEventClass(&lldbDebugger, eventClass, mask)
    }
    
    public func resume() {
        if thread != nil {
            return
        }
        
        let thread = Foundation.Thread {
            var lldbEvent = lldb.SBEvent()
            var lldbListener = self.lldbListener
            while !Foundation.Thread.current.isCancelled {
                if lldbListener.WaitForEvent(1, &lldbEvent) {
                    let event = Event(lldbEvent)
                    self.eventHandler(event)
                }
            }
        }
        self.thread = thread
        thread.start()
    }
    
    public func cancel() {
        thread?.cancel()
        thread = nil
    }
}
