import CxxLLDB

public final class Debugger {
    let lldbDebugger = lldb.SBDebugger.Create(false)
    
    public static func initialize() throws {
        try lldb.SBDebugger.InitializeWithErrorHandling().throwOnFail()
    }
    
    public static func terminate() {
        lldb.SBDebugger.Terminate()
    }
    
    public init() {
    }
    
    deinit {
        var lldbDebugger = lldbDebugger
        lldb.SBDebugger.Destroy(&lldbDebugger)
    }
    
    public var commandInterpreter: CommandInterpreter {
        var lldbDebugger = lldbDebugger
        return CommandInterpreter(lldbDebugger.GetCommandInterpreter())
    }
    
    public var targets: [Target] {
        var lldbDebugger = lldbDebugger
        let count = lldbDebugger.GetNumTargets()
        return (0 ..< count).map { Target(lldbDebugger.GetTargetAtIndex($0)) }
    }
    
    public var selectedTarget: Target? {
        var lldbDebugger = lldbDebugger
        let lldbTarget = lldbDebugger.GetSelectedTarget()
        if lldbTarget.IsValid() {
            return Target(lldbTarget)
        }
        else {
            return nil
        }
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
        return Target(lldbTarget)
    }
    
    public func createTarget(path: String, architecture: Architecture = .system) throws -> Target {
        var lldbDebugger = lldbDebugger
        let lldbTarget = lldbDebugger.CreateTargetWithFileAndArch(path, architecture.rawValue)
        return Target(lldbTarget)
    }
    
    public func findTarget(path: String, architecture: Architecture = .system) -> Target? {
        var lldbDebugger = lldbDebugger
        let lldbTarget = lldbDebugger.FindTargetWithFileAndArch(path, architecture.rawValue)
        if lldbTarget.IsValid() {
            return Target(lldbTarget)
        }
        else {
            return nil
        }
    }
    
    public func findTarget(processIdentifier: UInt64) -> Target? {
        var lldbDebugger = lldbDebugger
        let lldbTarget = lldbDebugger.FindTargetWithProcessID(lldb.pid_t(processIdentifier))
        if lldbTarget.IsValid() {
            return Target(lldbTarget)
        }
        else {
            return nil
        }
    }
    
    @discardableResult
    public func deleteTarget(_ target: Target) -> Bool {
        var lldbDebugger = lldbDebugger
        var lldbTarget = target.lldbTarget
        return lldbDebugger.DeleteTarget(&lldbTarget)
    }
    
    public struct AvailablePlatform: Equatable {
        public let name: String
        public let descriptiveText: String?
        
        init(name: String, descriptiveText: String?) {
            self.name = name
            self.descriptiveText = descriptiveText
        }
    }
    
    public var availablePlatforms: [AvailablePlatform] {
        var lldbDebugger = lldbDebugger
        let count = lldbDebugger.GetNumAvailablePlatforms()
        return (0 ..< count).map { idx in
            let lldbPlatformInfo = lldbDebugger.GetAvailablePlatformInfoAtIndex(idx)
            
            let name = withUnsafeTemporaryAllocation(of: CChar.self, capacity: 255) { buffer in
                lldbPlatformInfo.GetValueForKey("name").GetStringValue(buffer.baseAddress, 255)
                return String(cString: buffer.baseAddress!)
            }
            
            let descriptiveText = withUnsafeTemporaryAllocation(of: CChar.self, capacity: 255) { buffer in
                lldbPlatformInfo.GetValueForKey("description").GetStringValue(buffer.baseAddress, 255)
                return String(cString: buffer.baseAddress!)
            }
            
            return AvailablePlatform(name: name, descriptiveText: descriptiveText)
        }
    }
    
    public var selectedPlatform: Platform? {
        var lldbDebugger = lldbDebugger
        let lldbPlatform = lldbDebugger.GetSelectedPlatform()
        if lldbPlatform.IsValid() {
            return Platform(lldbPlatform)
        }
        else {
            return nil
        }
    }
    
    public func setSelectedPlatform(_ platform: Platform) {
        var lldbDebugger = lldbDebugger
        var lldbPlatform = platform.lldbPlatform
        lldbDebugger.SetSelectedPlatform(&lldbPlatform)
    }
}
