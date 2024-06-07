import CxxLLDB

public struct Breakpoint: Equatable, Identifiable {
    let lldbBreakpoint: lldb.SBBreakpoint
    
    init(_ lldbBreakpoint: lldb.SBBreakpoint) {
        self.lldbBreakpoint = lldbBreakpoint
    }
    
    public static func == (lhs: Breakpoint, rhs: Breakpoint) -> Bool {
        var lhsv = lhs.lldbBreakpoint
        return lhsv == rhs.lldbBreakpoint
    }
    
    public var id: Int {
        Int(lldbBreakpoint.GetID())
    }
    
    public var isEnabled: Bool {
        get {
            var lldbBreakpoint = lldbBreakpoint
            return lldbBreakpoint.IsEnabled()
        }
        set {
            var lldbBreakpoint = lldbBreakpoint
            lldbBreakpoint.SetEnabled(newValue)
        }
    }
    
    public var condition: String? {
        get {
            var lldbBreakpoint = lldbBreakpoint
            if let str = lldbBreakpoint.GetCondition() {
                return String(cString: str)
            }
            else {
                return nil
            }
        }
        set {
            var lldbBreakpoint = lldbBreakpoint
            lldbBreakpoint.SetCondition(newValue)
        }
    }
    
    public var isOneShot: Bool {
        get {
            return lldbBreakpoint.IsOneShot()
        }
        set {
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
        set {
            var lldbBreakpoint = lldbBreakpoint
            lldbBreakpoint.SetIgnoreCount(UInt32(truncatingIfNeeded: newValue))
        }
    }
    
    public var autoContinue: Bool {
        get {
            var lldbBreakpoint = lldbBreakpoint
            return lldbBreakpoint.GetAutoContinue()
        }
        set {
            var lldbBreakpoint = lldbBreakpoint
            lldbBreakpoint.SetAutoContinue(newValue)
        }
    }
    
    fileprivate class CallbackInfo {
        let callback: (Process, Thread, BreakpointLocation) -> Bool
        
        init(callback: @escaping (Process, Thread, BreakpointLocation) -> Bool) {
            self.callback = callback
        }
    }
    
    private static var callbackInfos: [Int: CallbackInfo] = [:]
    private static let callbackInfosLock: UnsafeMutablePointer<os_unfair_lock> = {
        let ptr = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        ptr.initialize(to: os_unfair_lock())
        return ptr
    }()
    
    public func setCallback(_ callback: ((Process, Thread, BreakpointLocation) -> Bool)?) {
        os_unfair_lock_lock(Self.callbackInfosLock)
        defer { os_unfair_lock_unlock(Self.callbackInfosLock) }
        let id = id
        var lldbBreakpoint = lldbBreakpoint
        if let callback {
            let info = CallbackInfo(callback: callback)
            Self.callbackInfos[id] = info
            let baton = Unmanaged.passUnretained(info).toOpaque()
            lldbBreakpoint.SetCallback(breakpointCallbackThunk, baton)
        }
        else {
            lldbBreakpoint.SetCallback(nil, nil)
            Self.callbackInfos[id] = nil
        }
    }
    
    public static func clearAllCallbacks() {
        os_unfair_lock_lock(Self.callbackInfosLock)
        defer { os_unfair_lock_unlock(Self.callbackInfosLock) }
        Self.callbackInfos.removeAll()
    }
}

private func breakpointCallbackThunk(baton: UnsafeMutableRawPointer?, process: UnsafeMutablePointer<lldb.SBProcess>, thread: UnsafeMutablePointer<lldb.SBThread>, location: UnsafeMutablePointer<lldb.SBBreakpointLocation>) -> Bool {
    guard let baton else { return true }
    let info = Unmanaged<Breakpoint.CallbackInfo>.fromOpaque(baton).takeUnretainedValue()
    return info.callback(Process(process.pointee), Thread(thread.pointee), BreakpointLocation(location.pointee))
}

public struct BreakpointLocation {
    let lldbLocation: lldb.SBBreakpointLocation
    
    init(_ lldbLocation: lldb.SBBreakpointLocation) {
        self.lldbLocation = lldbLocation
    }
    
    public var id: Int {
        var lldbLocation = lldbLocation
        return Int(lldbLocation.GetID())
    }
    
    public var isEnabled: Bool {
        get {
            var lldbLocation = lldbLocation
            return lldbLocation.IsEnabled()
        }
        set {
            var lldbLocation = lldbLocation
            lldbLocation.SetEnabled(newValue)
        }
    }
    
    public var condition: String? {
        get {
            var lldbLocation = lldbLocation
            if let str = lldbLocation.GetCondition() {
                return String(cString: str)
            }
            else {
                return nil
            }
        }
        set {
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
        set {
            var lldbLocation = lldbLocation
            lldbLocation.SetIgnoreCount(UInt32(truncatingIfNeeded: newValue))
        }
    }
    
    public var autoContinue: Bool {
        get {
            var lldbLocation = lldbLocation
            return lldbLocation.GetAutoContinue()
        }
        set {
            var lldbLocation = lldbLocation
            lldbLocation.SetAutoContinue(newValue)
        }
    }
    
    public var isResolved: Bool {
        var lldbLocation = lldbLocation
        return lldbLocation.IsResolved()
    }
}

public struct BreakpointEvent {
    let lldbEvent: lldb.SBEvent
    
    init(_ lldbEvent: lldb.SBEvent) {
        self.lldbEvent = lldbEvent
    }
    
    public init?(_ event: Event) {
        let lldbEvent = event.lldbEvent
        if lldb.SBBreakpoint.EventIsBreakpointEvent(lldbEvent) {
            self.init(lldbEvent)
        }
        else {
            return nil
        }
    }
    
    public var breakpoint: Breakpoint {
        Breakpoint(lldb.SBBreakpoint.GetBreakpointFromEvent(lldbEvent))
    }
    
    public var eventType: BreakpointEventType {
        BreakpointEventType(lldb.SBBreakpoint.GetBreakpointEventTypeFromEvent(lldbEvent))
    }
    
    public var locationCount: Int {
        Int(lldb.SBBreakpoint.GetNumBreakpointLocationsFromEvent(lldbEvent))
    }
}

public struct BreakpointEventType: OptionSet {
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
