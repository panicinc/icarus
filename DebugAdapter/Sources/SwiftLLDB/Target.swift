import CxxLLDB

public struct Target: Equatable {
    let lldbTarget: lldb.SBTarget
    
    init(_ lldbTarget: lldb.SBTarget) {
        self.lldbTarget = lldbTarget
    }
    
    public static func == (lhs: Target, rhs: Target) -> Bool {
        return lhs.lldbTarget == rhs.lldbTarget
    }
    
    public static let broadcasterClassName = String(cString: lldb.SBTarget.GetBroadcasterClassName())
    
    public var triple: String? {
        var lldbTarget = lldbTarget
        if let str = lldbTarget.GetTriple() {
            return String(cString: str)
        }
        else {
            return nil
        }
    }
    
    public var abiName: String? {
        var lldbTarget = lldbTarget
        if let str = lldbTarget.GetABIName() {
            return String(cString: str)
        }
        else {
            return nil
        }
    }
    
    public var process: Process? {
        var lldbTarget = lldbTarget
        let lldbProcess = lldbTarget.GetProcess()
        if lldbProcess.IsValid() {
            return Process(lldbProcess)
        }
        else {
            return nil
        }
    }
    
    public var platform: Platform? {
        var lldbTarget = lldbTarget
        let lldbPlatform = lldbTarget.GetPlatform()
        if lldbPlatform.IsValid() {
            return Platform(lldbPlatform)
        }
        else {
            return nil
        }
    }
    
    public struct LaunchOptions: Equatable {
        public var arguments: [String]?
        public var environment: [String: String]?
        public var workingDirectory: String?
        public var stopAtEntry = false
        
        public init() {
        }
    }
    
    public func launch(with options: LaunchOptions) throws -> Process {
        var lldbTarget = lldbTarget
        var lldbLaunchInfo = lldbTarget.GetLaunchInfo()
        
        if let arguments = options.arguments {
            var args = arguments.map { UnsafePointer<CChar>($0.withCString { strdup($0) }) }
            args.append(nil)
            lldbLaunchInfo.SetArguments(&args, true)
            args.forEach { $0?.deallocate() }
        }
        
        if let environment = options.environment {
            var env = lldb.SBEnvironment()
            for (key, value) in environment {
                env.Set(key, value, true)
            }
            lldbLaunchInfo.SetEnvironment(env, true)
        }
        
        if let workingDirectory = options.workingDirectory {
            lldbLaunchInfo.SetWorkingDirectory(workingDirectory)
        }
        
        var launchFlags = lldbLaunchInfo.GetLaunchFlags()
        if options.stopAtEntry {
            launchFlags |= lldb.eLaunchFlagStopAtEntry.rawValue
        }
        lldbLaunchInfo.SetLaunchFlags(launchFlags)
        
        var error = lldb.SBError()
        let lldbProcess = lldbTarget.Launch(&lldbLaunchInfo, &error)
        try error.throwOnFail()
        return Process(lldbProcess)
    }
    
    public struct AttachOptions: Equatable {
        public enum AttachTarget: Equatable {
            case processIdentifier(UInt64)
            case executablePath(String)
        }
        public var target: AttachTarget
        public var waitForLaunch = false
        public var stopAtEntry = false
        
        public init(processIdentifier: UInt64) {
            self.target = .processIdentifier(processIdentifier)
        }
        
        public init(executablePath: String) {
            self.target = .executablePath(executablePath)
        }
    }
    
    public func attach(with options: AttachOptions) throws -> Process {
        var lldbTarget = lldbTarget
        var lldbAttachInfo = lldb.SBAttachInfo()
        
        switch options.target {
        case let .processIdentifier(processIdentifier):
            lldbAttachInfo.SetProcessID(lldb.pid_t(processIdentifier))
        case let .executablePath(executablePath):
            lldbAttachInfo.SetExecutable(executablePath)
        }
        
        lldbAttachInfo.SetWaitForLaunch(options.waitForLaunch, true)
        lldbAttachInfo.SetIgnoreExisting(false)
        
        var error = lldb.SBError()
        let lldbProcess = lldbTarget.Attach(&lldbAttachInfo, &error)
        try error.throwOnFail()
        return Process(lldbProcess)
    }
    
    public func createBreakpoint(path: String, line: Int) -> Breakpoint {
        var lldbTarget = lldbTarget
        return Breakpoint(lldbTarget.BreakpointCreateByLocation(path, UInt32(line)))
    }
    
    public func createBreakpoint(path: String, line: Int, column: Int?, offset: Int?, moveToNearestCode: Bool) -> Breakpoint {
        var lldbTarget = lldbTarget
        let lldbFileSpec = lldb.SBFileSpec(path)
        var lldbModuleList = lldb.SBFileSpecList()
        return Breakpoint(lldbTarget.BreakpointCreateByLocation(lldbFileSpec, UInt32(line), UInt32(column ?? 0), lldb.addr_t(offset ?? 0), &lldbModuleList, moveToNearestCode))
    }
    
    public func createBreakpoint(name: String) -> Breakpoint {
        var lldbTarget = lldbTarget
        return Breakpoint(lldbTarget.BreakpointCreateByName(name, nil))
    }
    
    public func createBreakpoint(forExceptionIn language: Language, onCatch: Bool, onThrow: Bool) -> Breakpoint {
        var lldbTarget = lldbTarget
        return Breakpoint(lldbTarget.BreakpointCreateForException(language.lldbLanguageType, onCatch, onThrow))
    }
    
    public func findBreakpoint(withID id: Int) -> Breakpoint? {
        var lldbTarget = lldbTarget
        let lldbBreakpoint = lldbTarget.FindBreakpointByID(lldb.break_id_t(id))
        if lldbBreakpoint.IsValid() {
            return Breakpoint(lldbBreakpoint)
        }
        else {
            return nil
        }
    }
    
    @discardableResult
    public func removeBreakpoint(withID id: Int) -> Bool {
        var lldbTarget = lldbTarget
        return lldbTarget.BreakpointDelete(lldb.break_id_t(id))
    }
    
    public func evaluate(expression: String) throws -> Value {
        var lldbTarget = lldbTarget
        var lldbValue = lldbTarget.EvaluateExpression(expression)
        try lldbValue.GetError().throwOnFail()
        return Value(lldbValue)
    }
}

public struct TargetEvent {
    let lldbEvent: lldb.SBEvent
    
    init(_ lldbEvent: lldb.SBEvent) {
        self.lldbEvent = lldbEvent
    }
    
    public init?(_ event: Event) {
        let lldbEvent = event.lldbEvent
        if lldb.SBTarget.EventIsTargetEvent(lldbEvent) {
            self.init(lldbEvent)
        }
        else {
            return nil
        }
    }
    
    public struct EventFlags: OptionSet, Hashable {
        public static let breakpointChanged = Self(rawValue: 1 << 0)
        public static let modulesLoaded = Self(rawValue: 1 << 1)
        public static let modulesUnloaded = Self(rawValue: 1 << 2)
        public static let watchpointChanged = Self(rawValue: 1 << 3)
        public static let symbolsLoaded = Self(rawValue: 1 << 4)
        
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    public var flags: EventFlags {
        EventFlags(rawValue: Int(lldbEvent.GetType()))
    }
    
    public var target: Target {
        Target(lldb.SBTarget.GetTargetFromEvent(lldbEvent))
    }
}
