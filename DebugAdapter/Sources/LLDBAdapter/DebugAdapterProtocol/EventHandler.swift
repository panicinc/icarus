import Foundation

/// Base protocol for any event handler.
public protocol DebugAdapterEventHandler {
    /// The primary method invoked to handle an incoming event.
    func handleEvent(_ event: DebugAdapterConnection.IncomingEvent)
}

/// Event handler for the standard set of Debug Adapter Protocol client-targeted events.
public protocol DebugAdapterClientEventHandler: DebugAdapterEventHandler {
    func breakpoint(_ event: DebugAdapter.BreakpointEvent)
    func capabilities(_ event: DebugAdapter.CapabilitiesEvent)
    func continued(_ event: DebugAdapter.ContinuedEvent)
    func exited(_ event: DebugAdapter.ExitedEvent)
    func initialized(_ event: DebugAdapter.InitializedEvent)
    func invalidated(_ event: DebugAdapter.InvalidatedEvent)
    func loadedSource(_ event: DebugAdapter.LoadedSourceEvent)
    func memory(_ event: DebugAdapter.MemoryEvent)
    func module(_ event: DebugAdapter.ModuleEvent)
    func output(_ event: DebugAdapter.OutputEvent)
    func process(_ event: DebugAdapter.ProcessEvent)
    func progressStart(_ event: DebugAdapter.ProgressStartEvent)
    func progressUpdate(_ event: DebugAdapter.ProgressUpdateEvent)
    func progressEnd(_ event: DebugAdapter.ProgressEndEvent)
    func stopped(_ event: DebugAdapter.StoppedEvent)
    func terminated(_ event: DebugAdapter.TerminatedEvent)
    func thread(_ event: DebugAdapter.ThreadEvent)
}

public extension DebugAdapterClientEventHandler {
    func handleEvent(_ event: DebugAdapterConnection.IncomingEvent) {
        do {
            try performDefaultHandling(for: event)
        }
        catch {
            event.reject(throwing: error)
        }
    }
    
    /// Performs the default handling for supported notification types.
    /// Event types that are not supported will return `false`.
    @discardableResult
    func performDefaultHandling(for event: DebugAdapterConnection.IncomingEvent) throws -> Bool {
        switch event.event {
        case DebugAdapter.BreakpointEvent.event:
            let event = try event.decode(DebugAdapter.BreakpointEvent.self)
            breakpoint(event)
            
        case DebugAdapter.CapabilitiesEvent.event:
            let event = try event.decode(DebugAdapter.CapabilitiesEvent.self)
            capabilities(event)
            
        case DebugAdapter.ContinuedEvent.event:
            let event = try event.decode(DebugAdapter.ContinuedEvent.self)
            continued(event)
            
        case DebugAdapter.ExitedEvent.event:
            let event = try event.decode(DebugAdapter.ExitedEvent.self)
            exited(event)
            
        case DebugAdapter.InitializedEvent.event:
            let event = try event.decode(DebugAdapter.InitializedEvent.self)
            initialized(event)
            
        case DebugAdapter.InvalidatedEvent.event:
            let event = try event.decode(DebugAdapter.InvalidatedEvent.self)
            invalidated(event)
            
        case DebugAdapter.LoadedSourceEvent.event:
            let event = try event.decode(DebugAdapter.LoadedSourceEvent.self)
            loadedSource(event)
            
        case DebugAdapter.MemoryEvent.event:
            let event = try event.decode(DebugAdapter.MemoryEvent.self)
            memory(event)
            
        case DebugAdapter.ModuleEvent.event:
            let event = try event.decode(DebugAdapter.ModuleEvent.self)
            module(event)
            
        case DebugAdapter.OutputEvent.event:
            let event = try event.decode(DebugAdapter.OutputEvent.self)
            output(event)
            
        case DebugAdapter.ProcessEvent.event:
            let event = try event.decode(DebugAdapter.ProcessEvent.self)
            process(event)
            
        case DebugAdapter.ProgressStartEvent.event:
            let event = try event.decode(DebugAdapter.ProgressStartEvent.self)
            progressStart(event)
            
        case DebugAdapter.ProgressUpdateEvent.event:
            let event = try event.decode(DebugAdapter.ProgressUpdateEvent.self)
            progressUpdate(event)
            
        case DebugAdapter.ProgressEndEvent.event:
            let event = try event.decode(DebugAdapter.ProgressEndEvent.self)
            progressEnd(event)
            
        case DebugAdapter.StoppedEvent.event:
            let event = try event.decode(DebugAdapter.StoppedEvent.self)
            stopped(event)
            
        case DebugAdapter.TerminatedEvent.event:
            let event = try event.decode(DebugAdapter.TerminatedEvent.self)
            terminated(event)
            
        case DebugAdapter.ThreadEvent.event:
            let event = try event.decode(DebugAdapter.ThreadEvent.self)
            thread(event)
            
        default:
            return false
        }
        
        return true
    }
    
    func breakpoint(_ event: DebugAdapter.BreakpointEvent) {}
    func capabilities(_ event: DebugAdapter.CapabilitiesEvent) {}
    func continued(_ event: DebugAdapter.ContinuedEvent) {}
    func exited(_ event: DebugAdapter.ExitedEvent) {}
    func initialized(_ event: DebugAdapter.InitializedEvent) {}
    func invalidated(_ event: DebugAdapter.InvalidatedEvent) {}
    func loadedSource(_ event: DebugAdapter.LoadedSourceEvent) {}
    func memory(_ event: DebugAdapter.MemoryEvent) {}
    func module(_ event: DebugAdapter.ModuleEvent) {}
    func output(_ event: DebugAdapter.OutputEvent) {}
    func process(_ event: DebugAdapter.ProcessEvent) {}
    func progressStart(_ event: DebugAdapter.ProgressStartEvent) {}
    func progressUpdate(_ event: DebugAdapter.ProgressUpdateEvent) {}
    func progressEnd(_ event: DebugAdapter.ProgressEndEvent) {}
    func stopped(_ event: DebugAdapter.StoppedEvent) {}
    func terminated(_ event: DebugAdapter.TerminatedEvent) {}
    func thread(_ event: DebugAdapter.ThreadEvent) {}
}
