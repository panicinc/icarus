import CxxLLDB

public struct Breakpoint: Sendable {
    nonisolated(unsafe) let lldbBreakpoint: lldb.SBBreakpoint
    
    init?(_ lldbBreakpoint: lldb.SBBreakpoint) {
        guard lldbBreakpoint.IsValid() else {
            return nil
        }
        self.lldbBreakpoint = lldbBreakpoint
    }
    
    init(unsafe lldbBreakpoint: lldb.SBBreakpoint) {
        self.lldbBreakpoint = lldbBreakpoint
    }
}

extension Breakpoint: Equatable {
    public static func == (lhs: Breakpoint, rhs: Breakpoint) -> Bool {
        var lhsv = lhs.lldbBreakpoint
        return lhsv == rhs.lldbBreakpoint
    }
}

extension Breakpoint: Identifiable {
    public var id: Int {
        return Int(lldbBreakpoint.GetID())
    }
}

extension Breakpoint {
    public var isEnabled: Bool {
        get {
            var lldbBreakpoint = lldbBreakpoint
            return lldbBreakpoint.IsEnabled()
        }
        nonmutating set {
            var lldbBreakpoint = lldbBreakpoint
            lldbBreakpoint.SetEnabled(newValue)
        }
    }
    
    public var condition: String? {
        get {
            var lldbBreakpoint = lldbBreakpoint
            return String(optionalCString: lldbBreakpoint.GetCondition())
        }
        nonmutating set {
            var lldbBreakpoint = lldbBreakpoint
            lldbBreakpoint.SetCondition(newValue)
        }
    }
    
    public var isOneShot: Bool {
        get {
            return lldbBreakpoint.IsOneShot()
        }
        nonmutating set {
            var lldbBreakpoint = lldbBreakpoint
            lldbBreakpoint.SetOneShot(newValue)
        }
    }
    
    public var hitCount: Int {
        return Int(lldbBreakpoint.GetHitCount())
    }
    
    public var ignoreCount: Int {
        get {
            return Int(lldbBreakpoint.GetIgnoreCount())
        }
        nonmutating set {
            var lldbBreakpoint = lldbBreakpoint
            lldbBreakpoint.SetIgnoreCount(UInt32(truncatingIfNeeded: newValue))
        }
    }
    
    public var autoContinue: Bool {
        get {
            var lldbBreakpoint = lldbBreakpoint
            return lldbBreakpoint.GetAutoContinue()
        }
        nonmutating set {
            var lldbBreakpoint = lldbBreakpoint
            lldbBreakpoint.SetAutoContinue(newValue)
        }
    }
    
    public var target: Target {
        return Target(unsafe: lldbBreakpoint.GetTarget())
    }
}

extension Breakpoint {
    public func addName(_ name: String) throws {
        var lldbBreakpoint = lldbBreakpoint
        let error = lldbBreakpoint.AddNameWithErrorHandling(name)
        try error.throwOnFail()
    }
    
    public func removeName(_ name: String) {
        var lldbBreakpoint = lldbBreakpoint
        lldbBreakpoint.RemoveName(name)
    }
    
    public func matchesName(_ name: String) -> Bool {
        var lldbBreakpoint = lldbBreakpoint
        return lldbBreakpoint.MatchesName(name)
    }
    
    public var names: StringList {
        var lldbBreakpoint = lldbBreakpoint
        var names = lldb.SBStringList()
        lldbBreakpoint.GetNames(&names)
        return StringList(names)
    }
}

extension Breakpoint {
    public struct Location: Sendable {
        nonisolated(unsafe) let lldbLocation: lldb.SBBreakpointLocation
        
        init?(_ lldbLocation: lldb.SBBreakpointLocation) {
            guard lldbLocation.IsValid() else {
                return nil
            }
            self.lldbLocation = lldbLocation
        }
        
        init(unsafe lldbLocation: lldb.SBBreakpointLocation) {
            self.lldbLocation = lldbLocation
        }
    }
    
    public struct Locations: Sendable, RandomAccessCollection {
        nonisolated(unsafe) let lldbBreakpoint: lldb.SBBreakpoint
        
        init(_ lldbBreakpoint: lldb.SBBreakpoint) {
            self.lldbBreakpoint = lldbBreakpoint
        }
        
        public var count: Int { lldbBreakpoint.GetNumLocations() }
        
        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { count }
        
        public subscript(position: Int) -> Location {
            var lldbBreakpoint = lldbBreakpoint
            return Location(unsafe: lldbBreakpoint.GetLocationAtIndex(UInt32(position)))
        }
    }
    
    public var locations: Locations { Locations(lldbBreakpoint) }
    
    public var resolvedLocationsCount: Int {
        return lldbBreakpoint.GetNumResolvedLocations()
    }
}

extension Breakpoint.Location {
    public var id: Int {
        var lldbLocation = lldbLocation
        return Int(lldbLocation.GetID())
    }
    
    public var address: Address? {
        var lldbLocation = lldbLocation
        return Address(lldbLocation.GetAddress())
    }
    
    public var loadAddress: UInt64 {
        var lldbLocation = lldbLocation
        return lldbLocation.GetLoadAddress()
    }
    
    public var isResolved: Bool {
        var lldbLocation = lldbLocation
        return lldbLocation.IsResolved()
    }
    
    public var isEnabled: Bool {
        get {
            var lldbLocation = lldbLocation
            return lldbLocation.IsEnabled()
        }
        nonmutating set {
            var lldbLocation = lldbLocation
            lldbLocation.SetEnabled(newValue)
        }
    }
    
    public var condition: String? {
        get {
            var lldbLocation = lldbLocation
            return String(optionalCString: lldbLocation.GetCondition())
        }
        nonmutating set {
            var lldbLocation = lldbLocation
            lldbLocation.SetCondition(newValue)
        }
    }
    
    public var hitCount: Int {
        var lldbLocation = lldbLocation
        return Int(lldbLocation.GetHitCount())
    }
    
    public var ignoreCount: Int {
        get {
            var lldbLocation = lldbLocation
            return Int(lldbLocation.GetIgnoreCount())
        }
        nonmutating set {
            var lldbLocation = lldbLocation
            lldbLocation.SetIgnoreCount(UInt32(truncatingIfNeeded: newValue))
        }
    }
    
    public var autoContinue: Bool {
        get {
            var lldbLocation = lldbLocation
            return lldbLocation.GetAutoContinue()
        }
        nonmutating set {
            var lldbLocation = lldbLocation
            lldbLocation.SetAutoContinue(newValue)
        }
    }
    
    public var threadName: String? {
        get {
            String(optionalCString: lldbLocation.GetThreadName())
        }
        set {
            var lldbLocation = lldbLocation
            lldbLocation.SetThreadName(newValue)
        }
    }
    
    public var queueName: String? {
        get {
            String(optionalCString: lldbLocation.GetQueueName())
        }
        set {
            var lldbLocation = lldbLocation
            lldbLocation.SetQueueName(threadName)
        }
    }
}

public struct BreakpointEvent: Sendable {
    nonisolated(unsafe) let lldbEvent: lldb.SBEvent
    
    init(_ lldbEvent: lldb.SBEvent) {
        self.lldbEvent = lldbEvent
    }
    
    public var breakpoint: Breakpoint {
        Breakpoint(unsafe: lldb.SBBreakpoint.GetBreakpointFromEvent(lldbEvent))
    }
    
    public struct EventType: RawRepresentable, Sendable, Hashable {
        public static let invalid = Self(lldb.eBreakpointEventTypeInvalidType)
        public static let added = Self(lldb.eBreakpointEventTypeAdded)
        public static let removed = Self(lldb.eBreakpointEventTypeRemoved)
        public static let locationsAdded = Self(lldb.eBreakpointEventTypeLocationsAdded)
        public static let locationsRemoved = Self(lldb.eBreakpointEventTypeLocationsRemoved)
        public static let locationsResolved = Self(lldb.eBreakpointEventTypeLocationsResolved)
        public static let enabled = Self(lldb.eBreakpointEventTypeEnabled)
        public static let disabled = Self(lldb.eBreakpointEventTypeDisabled)
        public static let commandChanged = Self(lldb.eBreakpointEventTypeCommandChanged)
        public static let conditionChanged = Self(lldb.eBreakpointEventTypeConditionChanged)
        public static let ignoreChanged = Self(lldb.eBreakpointEventTypeIgnoreChanged)
        public static let threadChanged = Self(lldb.eBreakpointEventTypeThreadChanged)
        public static let autoContinueChanged = Self(lldb.eBreakpointEventTypeAutoContinueChanged)
        
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        init(_ value: lldb.BreakpointEventType) {
            self.rawValue = Int(value.rawValue)
        }
    }
    
    public var eventType: EventType {
        return EventType(lldb.SBBreakpoint.GetBreakpointEventTypeFromEvent(lldbEvent))
    }
    
    public var locationCount: Int {
        return Int(lldb.SBBreakpoint.GetNumBreakpointLocationsFromEvent(lldbEvent))
    }
}
