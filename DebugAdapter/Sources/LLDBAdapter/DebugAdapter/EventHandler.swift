import Foundation

/// Base protocol for any event handler.
public protocol DebugAdapterEventHandler {
    /// The primary method invoked to parse and handle an event.
    /// Handlers may override this method to perform special handling of standard or custom events, and may invoke
    /// `performDefaultHanding(forEvent:data:connection:)` to delegate to the default implementation for events not handled.
    func handleEvent(_ event: String, data: Data, connection: DebugAdapterConnection) throws
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
    func progressEnd(_ event: DebugAdapter.ProgressEndEvent)
    func progressStart(_ event: DebugAdapter.ProgressStartEvent)
    func progressUpdate(_ event: DebugAdapter.ProgressUpdateEvent)
    func stopped(_ event: DebugAdapter.StoppedEvent)
    func terminated(_ event: DebugAdapter.TerminatedEvent)
    func thread(_ event: DebugAdapter.ThreadEvent)
}

public extension DebugAdapterClientEventHandler {
    func handleEvent(_ event: String, data: Data, connection: DebugAdapterConnection) throws {
        try performDefaultHandling(forEvent: event, data: data, connection: connection)
    }
    
    /// Performs the default handling for supported notification types.
    /// Event types that are not supported will return `false`.
    @discardableResult
    func performDefaultHandling(forEvent event: String, data: Data, connection: DebugAdapterConnection) throws -> Bool {
        switch event {
        case DebugAdapter.BreakpointEvent.event:
            let event = try connection.decode(DebugAdapter.BreakpointEvent.self, from: data)
            breakpoint(event)
            
        case DebugAdapter.CapabilitiesEvent.event:
            let event = try connection.decode(DebugAdapter.CapabilitiesEvent.self, from: data)
            capabilities(event)
            
        case DebugAdapter.ContinuedEvent.event:
            let event = try connection.decode(DebugAdapter.ContinuedEvent.self, from: data)
            continued(event)
            
        case DebugAdapter.ExitedEvent.event:
            let event = try connection.decode(DebugAdapter.ExitedEvent.self, from: data)
            exited(event)
            
        case DebugAdapter.InitializedEvent.event:
            let event = try connection.decode(DebugAdapter.InitializedEvent.self, from: data)
            initialized(event)
            
        case DebugAdapter.InvalidatedEvent.event:
            let event = try connection.decode(DebugAdapter.InvalidatedEvent.self, from: data)
            invalidated(event)
            
        case DebugAdapter.LoadedSourceEvent.event:
            let event = try connection.decode(DebugAdapter.LoadedSourceEvent.self, from: data)
            loadedSource(event)
            
        case DebugAdapter.MemoryEvent.event:
            let event = try connection.decode(DebugAdapter.MemoryEvent.self, from: data)
            memory(event)
            
        case DebugAdapter.ModuleEvent.event:
            let event = try connection.decode(DebugAdapter.ModuleEvent.self, from: data)
            module(event)
            
        case DebugAdapter.OutputEvent.event:
            let event = try connection.decode(DebugAdapter.OutputEvent.self, from: data)
            output(event)
            
        case DebugAdapter.ProcessEvent.event:
            let event = try connection.decode(DebugAdapter.ProcessEvent.self, from: data)
            process(event)
            
        case DebugAdapter.ProgressEndEvent.event:
            let event = try connection.decode(DebugAdapter.ProgressEndEvent.self, from: data)
            progressEnd(event)
            
        case DebugAdapter.ProgressStartEvent.event:
            let event = try connection.decode(DebugAdapter.ProgressStartEvent.self, from: data)
            progressStart(event)
            
        case DebugAdapter.ProgressUpdateEvent.event:
            let event = try connection.decode(DebugAdapter.ProgressUpdateEvent.self, from: data)
            progressUpdate(event)
            
        case DebugAdapter.StoppedEvent.event:
            let event = try connection.decode(DebugAdapter.StoppedEvent.self, from: data)
            stopped(event)
            
        case DebugAdapter.TerminatedEvent.event:
            let event = try connection.decode(DebugAdapter.TerminatedEvent.self, from: data)
            terminated(event)
            
        case DebugAdapter.ThreadEvent.event:
            let event = try connection.decode(DebugAdapter.ThreadEvent.self, from: data)
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
    func progressEnd(_ event: DebugAdapter.ProgressEndEvent) {}
    func progressStart(_ event: DebugAdapter.ProgressStartEvent) {}
    func progressUpdate(_ event: DebugAdapter.ProgressUpdateEvent) {}
    func stopped(_ event: DebugAdapter.StoppedEvent) {}
    func terminated(_ event: DebugAdapter.TerminatedEvent) {}
    func thread(_ event: DebugAdapter.ThreadEvent) {}
}
