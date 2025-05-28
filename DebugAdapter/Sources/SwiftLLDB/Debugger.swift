import CxxLLDB

public final class Debugger: Sendable {
    nonisolated(unsafe) let lldbDebugger = lldb.SBDebugger.Create(false)
    
    public init() {
    }
    
    deinit {
        var lldbDebugger = lldbDebugger
        lldb.SBDebugger.Destroy(&lldbDebugger)
    }
}

extension Debugger {
    public static func initialize() throws {
        try lldb.SBDebugger.InitializeWithErrorHandling().throwOnFail()
    }
    
    public static func terminate() {
        lldb.SBDebugger.Terminate()
    }
}

extension Debugger {
    public struct AvailablePlatform: Sendable, Equatable {
        public let name: String
        public let caption: String?
        
        init(name: String, caption: String?) {
            self.name = name
            self.caption = caption
        }
    }
    
    public struct AvailablePlatforms: Sendable, RandomAccessCollection {
        nonisolated(unsafe) let lldbDebugger: lldb.SBDebugger
        
        init(_ lldbDebugger: lldb.SBDebugger) {
            self.lldbDebugger = lldbDebugger
        }
        
        public var count: Int {
            var lldbDebugger = lldbDebugger
            return Int(lldbDebugger.GetNumAvailablePlatforms())
        }
        
        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { count }
        
        public subscript(position: Int) -> AvailablePlatform {
            var lldbDebugger = lldbDebugger
            let info = StructuredData(unsafe: lldbDebugger.GetAvailablePlatformInfoAtIndex(UInt32(position)))
            
            let name = info["name"]?.asString() ?? "<unknown>"
            let caption = info["description"]?.asString()
            
            return AvailablePlatform(name: name, caption: caption)
        }
    }
    
    public var availablePlatforms: AvailablePlatforms { AvailablePlatforms(lldbDebugger) }
    
    public var selectedPlatform: Platform? {
        get {
            var lldbDebugger = lldbDebugger
            return Platform(lldbDebugger.GetSelectedPlatform())
        }
        set {
            var lldbDebugger = lldbDebugger
            var lldbPlatform = newValue?.lldbPlatform ?? lldb.SBPlatform()
            lldbDebugger.SetSelectedPlatform(&lldbPlatform)
        }
    }
}

extension Debugger {
    public struct Targets: Sendable, RandomAccessCollection {
        nonisolated(unsafe) let lldbDebugger: lldb.SBDebugger
        
        init(_ lldbDebugger: lldb.SBDebugger) {
            self.lldbDebugger = lldbDebugger
        }
        
        public var count: Int {
            var lldbDebugger = lldbDebugger
            return Int(lldbDebugger.GetNumTargets())
        }
        
        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { count }
        
        public subscript(position: Int) -> Target {
            var lldbDebugger = lldbDebugger
            return Target(unsafe: lldbDebugger.GetTargetAtIndex(UInt32(position)))
        }
    }
    
    public var targets: Targets { Targets(lldbDebugger) }
    
    public var selectedTarget: Target? {
        var lldbDebugger = lldbDebugger
        let lldbTarget = lldbDebugger.GetSelectedTarget()
        return Target(lldbTarget)
    }
    
    public func setSelectedTarget(_ target: Target) {
        var lldbDebugger = lldbDebugger
        var lldbTarget = target.lldbTarget
        lldbDebugger.SetSelectedTarget(&lldbTarget)
    }
    
    public func createTarget(path: String, triple: String? = nil, platform: String? = nil) throws -> Target {
        var lldbDebugger = lldbDebugger
        var error = lldb.SBError()
        let lldbTarget = lldbDebugger.CreateTarget(path, triple, platform, true, &error)
        try error.throwOnFail()
        return Target(unsafe: lldbTarget)
    }
    
    public func createTarget(path: String, architecture: Architecture = .system) throws -> Target {
        var lldbDebugger = lldbDebugger
        let lldbTarget = lldbDebugger.CreateTargetWithFileAndArch(path, architecture.rawValue)
        return Target(unsafe: lldbTarget)
    }
    
    public func findTarget(path: String, architecture: Architecture = .system) -> Target? {
        var lldbDebugger = lldbDebugger
        let lldbTarget = lldbDebugger.FindTargetWithFileAndArch(path, architecture.rawValue)
        return Target(unsafe: lldbTarget)
    }
    
    public func findTarget(processID: UInt64) -> Target? {
        var lldbDebugger = lldbDebugger
        let lldbTarget = lldbDebugger.FindTargetWithProcessID(lldb.pid_t(processID))
        return Target(lldbTarget)
    }
    
    @discardableResult
    public func deleteTarget(_ target: Target) -> Bool {
        var lldbDebugger = lldbDebugger
        var lldbTarget = target.lldbTarget
        return lldbDebugger.DeleteTarget(&lldbTarget)
    }
}

extension Debugger {
    public struct Events: AsyncSequence {
        fileprivate let debugger: Debugger
        
        fileprivate init(_ debugger: Debugger) {
            self.debugger = debugger
        }
        
        public struct AsyncIterator: AsyncIteratorProtocol {
            fileprivate let debugger: Debugger
            
            fileprivate var listener: lldb.SBListener
            
            init(_ debugger: Debugger) {
                self.debugger = debugger
                var lldbDebugger = debugger.lldbDebugger
                self.listener = lldbDebugger.GetListener()
            }
            
            public mutating func next() async -> Event? {
                while !Task.isCancelled {
                    var lldbEvent = lldb.SBEvent()
                    if listener.WaitForEvent(1, &lldbEvent),
                       let event = Event(lldbEvent) {
                        return event
                    }
                    await Task.yield()
                }
                return nil
            }
        }
        
        public func makeAsyncIterator() -> AsyncIterator {
            return AsyncIterator(debugger)
        }
    }
    
    public var events: Events { Events(self) }
    
    public func startListening(to target: Target, events: TargetEvent.EventType) {
        var lldbDebugger = lldbDebugger
        var listener = lldbDebugger.GetListener()
        
        let targetBroadcaster = target.lldbTarget.GetBroadcaster()
        listener.StartListeningForEvents(targetBroadcaster, events.rawValue);
    }
}

extension Debugger {
    public var commandInterpreter: CommandInterpreter {
        var lldbDebugger = lldbDebugger
        return CommandInterpreter(lldbDebugger.GetCommandInterpreter())
    }
}
