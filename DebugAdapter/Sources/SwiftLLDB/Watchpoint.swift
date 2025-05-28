import CxxLLDB

public struct Watchpoint: Sendable {
    nonisolated(unsafe) let lldbWatchpoint: lldb.SBWatchpoint
    
    init?(_ lldbWatchpoint: lldb.SBWatchpoint) {
        guard lldbWatchpoint.IsValid() else {
            return nil
        }
        self.lldbWatchpoint = lldbWatchpoint
    }
    
    init(unsafe lldbWatchpoint: lldb.SBWatchpoint) {
        self.lldbWatchpoint = lldbWatchpoint
    }
}

extension Watchpoint: Equatable {
    public static func == (lhs: Watchpoint, rhs: Watchpoint) -> Bool {
        return lhs.lldbWatchpoint == rhs.lldbWatchpoint
    }
}

extension Watchpoint: Identifiable {
    public var id: Int {
        var lldbWatchpoint = lldbWatchpoint
        return Int(lldbWatchpoint.GetID())
    }
}

extension Watchpoint {
    public var isEnabled: Bool {
        get {
            var lldbWatchpoint = lldbWatchpoint
            return lldbWatchpoint.IsEnabled()
        }
        nonmutating set {
            var lldbWatchpoint = lldbWatchpoint
            lldbWatchpoint.SetEnabled(newValue)
        }
    }
    
    public var condition: String? {
        get {
            var lldbWatchpoint = lldbWatchpoint
            return String(optionalCString: lldbWatchpoint.GetCondition())
        }
        nonmutating set {
            var lldbWatchpoint = lldbWatchpoint
            lldbWatchpoint.SetCondition(newValue)
        }
    }
    
    public var hitCount: Int {
        var lldbWatchpoint = lldbWatchpoint
        return Int(lldbWatchpoint.GetHitCount())
    }
    
    public var ignoreCount: Int {
        get {
            var lldbWatchpoint = lldbWatchpoint
            return Int(lldbWatchpoint.GetIgnoreCount())
        }
        nonmutating set {
            var lldbWatchpoint = lldbWatchpoint
            lldbWatchpoint.SetIgnoreCount(UInt32(truncatingIfNeeded: newValue))
        }
    }
}