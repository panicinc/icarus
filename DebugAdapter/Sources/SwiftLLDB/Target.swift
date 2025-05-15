import CxxLLDB

public struct Target: Sendable {
    let lldbTarget: lldb.SBTarget
    
    init?(_ lldbTarget: lldb.SBTarget) {
        guard lldbTarget.IsValid() else {
            return nil
        }
        self.lldbTarget = lldbTarget
    }
    
    init(unsafe lldbTarget: lldb.SBTarget) {
        self.lldbTarget = lldbTarget
    }
}

extension Target: Equatable {
    public static func == (lhs: Target, rhs: Target) -> Bool {
        return lhs.lldbTarget == rhs.lldbTarget
    }
}

extension Target {
    public var triple: String? {
        var lldbTarget = lldbTarget
        return String(optionalCString: lldbTarget.GetTriple())
    }
    
    public var abiName: String? {
        var lldbTarget = lldbTarget
        return String(optionalCString: lldbTarget.GetABIName())
    }
    
    public var process: Process? {
        var lldbTarget = lldbTarget
        return Process(lldbTarget.GetProcess())
    }
    
    public var platform: Platform? {
        var lldbTarget = lldbTarget
        return Platform(lldbTarget.GetPlatform())
    }
}

extension Target {
    public struct LaunchOptions: Sendable, Equatable {
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
        return Process(unsafe: lldbProcess)
    }
}

extension Target {
    public struct AttachOptions: Sendable, Equatable {
        public enum AttachTarget: Sendable, Equatable {
            case processID(UInt64)
            case path(String)
        }
        public var target: AttachTarget
        public var waitForLaunch = false
        
        public init(processID: UInt64) {
            self.target = .processID(processID)
        }
        
        public init(path: String) {
            self.target = .path(path)
        }
    }
    
    public func attach(with options: AttachOptions) throws -> Process {
        var lldbTarget = lldbTarget
        var lldbAttachInfo = lldb.SBAttachInfo()
        
        switch options.target {
        case let .processID(processID):
            lldbAttachInfo.SetProcessID(lldb.pid_t(processID))
        case let .path(path):
            lldbAttachInfo.SetExecutable(path)
        }
        
        lldbAttachInfo.SetWaitForLaunch(options.waitForLaunch, true)
        lldbAttachInfo.SetIgnoreExisting(false)
        
        var error = lldb.SBError()
        let lldbProcess = lldbTarget.Attach(&lldbAttachInfo, &error)
        try error.throwOnFail()
        return Process(unsafe: lldbProcess)
    }
}

extension Target {
    public func createBreakpoint(path: String, line: Int) -> Breakpoint {
        var lldbTarget = lldbTarget
        return Breakpoint(unsafe: lldbTarget.BreakpointCreateByLocation(path, UInt32(line)))
    }
    
    public func createBreakpoint(path: String, line: Int, column: Int? = nil, offset: Int? = nil, moveToNearestCode: Bool = true) -> Breakpoint {
        var lldbTarget = lldbTarget
        let lldbFileSpec = lldb.SBFileSpec(path)
        var lldbModuleList = lldb.SBFileSpecList()
        return Breakpoint(unsafe: lldbTarget.BreakpointCreateByLocation(lldbFileSpec, UInt32(line), UInt32(column ?? 0), UInt64(offset ?? 0), &lldbModuleList, moveToNearestCode))
    }
    
    public func createBreakpoint(name: String) -> Breakpoint {
        var lldbTarget = lldbTarget
        return Breakpoint(unsafe: lldbTarget.BreakpointCreateByName(name, nil))
    }
    
    public func createBreakpoint(address: UInt64) -> Breakpoint {
        var lldbTarget = lldbTarget
        return Breakpoint(unsafe: lldbTarget.BreakpointCreateByAddress(address))
    }
    
    public func createBreakpoint(forExceptionIn language: Language, onCatch: Bool, onThrow: Bool) -> Breakpoint {
        var lldbTarget = lldbTarget
        return Breakpoint(unsafe: lldbTarget.BreakpointCreateForException(language.lldbLanguageType, onCatch, onThrow))
    }
    
    public func findBreakpoint(id: Int) -> Breakpoint? {
        var lldbTarget = lldbTarget
        let lldbBreakpoint = lldbTarget.FindBreakpointByID(lldb.break_id_t(id))
        return Breakpoint(lldbBreakpoint)
    }
    
    @discardableResult
    public func removeBreakpoint(id: Int) -> Bool {
        var lldbTarget = lldbTarget
        return lldbTarget.BreakpointDelete(lldb.break_id_t(id))
    }
    
    @discardableResult
    public func removeAllBreakpoints() -> Bool {
        var lldbTarget = lldbTarget
        return lldbTarget.DeleteAllBreakpoints()
    }
}

extension Target {
    public func createWatchpoint(at address: UInt64, count: Int, onRead: Bool, onWrite: Bool) throws -> Watchpoint {
        var options = lldb.SBWatchpointOptions()
        options.SetWatchpointTypeRead(onRead)
        options.SetWatchpointTypeWrite(onWrite ? lldb.eWatchpointWriteTypeOnModify : lldb.eWatchpointWriteTypeDisabled)
        
        var lldbTarget = lldbTarget
        var error = lldb.SBError()
        let lldbWatchpoint = lldbTarget.WatchpointCreateByAddress(address, count, options, &error)
        try error.throwOnFail()
        return Watchpoint(unsafe: lldbWatchpoint)
    }
    
    public func findWatchpoint(id: Int) -> Watchpoint? {
        var lldbTarget = lldbTarget
        let lldbWatchpoint = lldbTarget.FindWatchpointByID(lldb.watch_id_t(id))
        return Watchpoint(lldbWatchpoint)
    }
    
    @discardableResult
    public func removeWatchpoint(id: Int) -> Bool {
        var lldbTarget = lldbTarget
        return lldbTarget.DeleteWatchpoint(lldb.watch_id_t(id))
    }
    
    @discardableResult
    public func removeAllWatchpoints() -> Bool {
        var lldbTarget = lldbTarget
        return lldbTarget.DeleteAllWatchpoints()
    }
}

extension Target {
    public func readInstructions(at address: Address, count: Int) -> InstructionList? {
        var lldbTarget = lldbTarget
        let lldbInstructionList = lldbTarget.ReadInstructions(address.lldbAddress, UInt32(count))
        return InstructionList(lldbInstructionList)
    }
}

extension Target {
    public func evaluate(expression: String) throws -> Value {
        var lldbTarget = lldbTarget
        var lldbValue = lldbTarget.EvaluateExpression(expression)
        try lldbValue.GetError().throwOnFail()
        return Value(unsafe: lldbValue)
    }
}

public struct TargetEvent: Sendable {
    let lldbEvent: lldb.SBEvent
    
    init(_ lldbEvent: lldb.SBEvent) {
        self.lldbEvent = lldbEvent
    }
    
    public struct EventType: OptionSet, Sendable, Hashable {
        public static let breakpointChanged = Self(rawValue: 1 << 0)
        public static let modulesLoaded = Self(rawValue: 1 << 1)
        public static let modulesUnloaded = Self(rawValue: 1 << 2)
        public static let watchpointChanged = Self(rawValue: 1 << 3)
        public static let symbolsLoaded = Self(rawValue: 1 << 4)
        
        public let rawValue: UInt32
        
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
    }
    
    public var eventType: EventType {
        return EventType(rawValue: lldbEvent.GetType())
    }
    
    public var target: Target {
        return Target(unsafe: lldb.SBTarget.GetTargetFromEvent(lldbEvent))
    }
}
