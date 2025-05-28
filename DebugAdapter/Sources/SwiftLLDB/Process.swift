import CxxLLDB

public struct Process: Sendable {
    nonisolated(unsafe) let lldbProcess: lldb.SBProcess
    
    init?(_ lldbProcess: lldb.SBProcess) {
        guard lldbProcess.IsValid() else {
            return nil
        }
        self.lldbProcess = lldbProcess
    }
    
    init(unsafe lldbProcess: lldb.SBProcess) {
        self.lldbProcess = lldbProcess
    }
}

extension Process {
    public struct State: RawRepresentable, Sendable, Hashable {
        public static let invalid = Self(lldb.eStateInvalid)
        public static let unloaded = Self(lldb.eStateUnloaded)
        public static let connected = Self(lldb.eStateConnected)
        public static let attaching = Self(lldb.eStateAttaching)
        public static let launching = Self(lldb.eStateLaunching)
        public static let stopped = Self(lldb.eStateStopped)
        public static let running = Self(lldb.eStateRunning)
        public static let stepping = Self(lldb.eStateStepping)
        public static let crashed = Self(lldb.eStateCrashed)
        public static let detached = Self(lldb.eStateDetached)
        public static let exited = Self(lldb.eStateExited)
        public static let suspended = Self(lldb.eStateSuspended)
        
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        init(_ value: lldb.StateType) {
            self.rawValue = Int(value.rawValue)
        }
        
        var lldbState: lldb.StateType { lldb.StateType(UInt32(truncatingIfNeeded: rawValue)) }
    }
    
    public var state: State {
        var lldbProcess = lldbProcess
        return State(lldbProcess.GetState())
    }
    
    public var processID: UInt64? {
        var lldbProcess = lldbProcess
        let pid = lldbProcess.GetProcessID()
        guard pid != LLDB_INVALID_PROCESS_ID else {
            return nil
        }
        return pid
    }
    
    public var byteOrder: ByteOrder {
        return ByteOrder(lldbProcess.GetByteOrder())
    }
    
    public struct Info: Sendable {
        let lldbInfo: lldb.SBProcessInfo
        
        init?(_ lldbInfo: lldb.SBProcessInfo) {
            guard lldbInfo.IsValid() else {
                return nil
            }
            self.lldbInfo = lldbInfo
        }
        
        init(unsafe lldbInfo: lldb.SBProcessInfo) {
            self.lldbInfo = lldbInfo
        }
    }
    
    public var info: Info {
        var lldbProcess = lldbProcess
        return Info(unsafe: lldbProcess.GetProcessInfo())
    }
    
    public var addressByteSize: Int {
        return Int(lldbProcess.GetAddressByteSize())
    }
    
    public var exitStatus: Int32 {
        var lldbProcess = lldbProcess
        return lldbProcess.GetExitStatus()
    }
    
    public var exitDescription: String? {
        var lldbProcess = lldbProcess
        return String(optionalCString: lldbProcess.GetExitDescription())
    }
}

extension Process {
    public struct Threads: Sendable, RandomAccessCollection {
        nonisolated(unsafe) let lldbProcess: lldb.SBProcess
        
        init(_ lldbProcess: lldb.SBProcess) {
            self.lldbProcess = lldbProcess
        }
        
        public var count: Int {
            var lldbProcess = lldbProcess
            return Int(lldbProcess.GetNumThreads())
        }
        
        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { count }
        
        public subscript(position: Int) -> Thread {
            var lldbProcess = lldbProcess
            return Thread(unsafe: lldbProcess.GetThreadAtIndex(position))
        }
    }
    
    public var threads: Threads { Threads(lldbProcess) }
    
    public func thread(withID id: Int) -> Thread? {
        var lldbProcess = lldbProcess
        return Thread(lldbProcess.GetThreadByID(lldb.tid_t(id)))
    }
    
    public func thread(withIndexID indexID: Int) -> Thread? {
        var lldbProcess = lldbProcess
        return Thread(lldbProcess.GetThreadByIndexID(UInt32(indexID)))
    }
    
    public var selectedThread: Thread? {
        return Thread(lldbProcess.GetSelectedThread())
    }
    
    @discardableResult
    public func setSelectedThread(_ thread: Thread) -> Bool {
        var lldbProcess = lldbProcess
        return lldbProcess.SetSelectedThread(thread.lldbThread)
    }
    
    @discardableResult
    public func setSelectedThread(byID id: UInt64) -> Bool {
        var lldbProcess = lldbProcess
        return lldbProcess.SetSelectedThreadByID(id)
    }
    
    @discardableResult
    public func setSelectedThread(byIndexID id: UInt32) -> Bool {
        var lldbProcess = lldbProcess
        return lldbProcess.SetSelectedThreadByIndexID(id)
    }
}

extension Process {
    public func resume() throws {
        var lldbProcess = lldbProcess
        let error = lldbProcess.Continue()
        try error.throwOnFail()
    }
    
    public func stop() throws {
        var lldbProcess = lldbProcess
        let error = lldbProcess.Stop()
        try error.throwOnFail()
    }
    
    public func kill() throws {
        var lldbProcess = lldbProcess
        let error = lldbProcess.Kill()
        try error.throwOnFail()
    }
    
    public func detach() throws {
        var lldbProcess = lldbProcess
        let error = lldbProcess.Detach()
        try error.throwOnFail()
    }
    
    public func signal(_ signal: Int32) throws {
        var lldbProcess = lldbProcess
        let error = lldbProcess.Signal(signal)
        try error.throwOnFail()
    }
}

extension Process {
    public func writeStandardIn(_ buffer: UnsafeBufferPointer<CChar>) -> Int {
        var lldbProcess = lldbProcess
        return lldbProcess.PutSTDIN(buffer.baseAddress, buffer.count)
    }
    
    public func readStandardOut(_ buffer: UnsafeMutableBufferPointer<CChar>) -> Int {
        return lldbProcess.GetSTDOUT(buffer.baseAddress, buffer.count)
    }
    
    public func readStandardError(_ buffer: UnsafeMutableBufferPointer<CChar>) -> Int {
        return lldbProcess.GetSTDERR(buffer.baseAddress, buffer.count)
    }
}

extension Process {
    public func memoryRegionInfo(at address: UInt64) throws -> MemoryRegionInfo {
        var lldbProcess = lldbProcess
        var region = lldb.SBMemoryRegionInfo()
        let error = lldbProcess.GetMemoryRegionInfo(address, &region)
        try error.throwOnFail()
        return MemoryRegionInfo(region)
    }
    
    public func readMemory(_ buffer: UnsafeMutableBufferPointer<UInt8>, at address: UInt64) throws -> Int {
        var lldbProcess = lldbProcess
        var error = lldb.SBError()
        let bytesRead = lldbProcess.ReadMemory(address, buffer.baseAddress, buffer.count, &error)
        try error.throwOnFail()
        return bytesRead
    }
    
    public func readMemory(_ buffer: UnsafeMutableRawBufferPointer, at address: UInt64) throws -> Int {
        var lldbProcess = lldbProcess
        var error = lldb.SBError()
        let bytesRead = lldbProcess.ReadMemory(address, buffer.baseAddress, buffer.count, &error)
        try error.throwOnFail()
        return bytesRead
    }
    
    public func writeMemory(_ buffer: UnsafeBufferPointer<UInt8>, at address: UInt64) throws -> Int {
        var lldbProcess = lldbProcess
        var error = lldb.SBError()
        let bytesWritten = lldbProcess.WriteMemory(address, buffer.baseAddress, buffer.count, &error)
        try error.throwOnFail()
        return bytesWritten
    }
    
    public func writeMemory(_ buffer: UnsafeRawBufferPointer, at address: UInt64) throws -> Int {
        var lldbProcess = lldbProcess
        var error = lldb.SBError()
        let bytesWritten = lldbProcess.WriteMemory(address, buffer.baseAddress, buffer.count, &error)
        try error.throwOnFail()
        return bytesWritten
    }
}

extension Process.Info {
    public var processID: UInt64? {
        var lldbInfo = lldbInfo
        let pid = lldbInfo.GetProcessID()
        guard pid != LLDB_INVALID_PROCESS_ID else {
            return nil
        }
        return pid
    }
    
    public var name: String {
        var lldbInfo = lldbInfo
        return String(optionalCString: lldbInfo.GetName()) ?? ""
    }
    
    public var triple: String {
        var lldbInfo = lldbInfo
        return String(optionalCString: lldbInfo.GetTriple()) ?? ""
    }
    
    public var userID: UInt32 {
        var lldbInfo = lldbInfo
        return lldbInfo.GetUserID()
    }
    
    public var isUserIDValid: Bool {
        var lldbInfo = lldbInfo
        return lldbInfo.UserIDIsValid()
    }
    
    public var effectiveUserID: UInt32 {
        var lldbInfo = lldbInfo
        return lldbInfo.GetEffectiveUserID()
    }
    
    public var groupID: UInt32 {
        var lldbInfo = lldbInfo
        return lldbInfo.GetGroupID()
    }
    
    public var isGroupIDValid: Bool {
        var lldbInfo = lldbInfo
        return lldbInfo.GroupIDIsValid()
    }
    
    public var effectiveGroupID: UInt32 {
        var lldbInfo = lldbInfo
        return lldbInfo.GetEffectiveGroupID()
    }
}

public struct ProcessEvent: Sendable {
    nonisolated(unsafe) let lldbEvent: lldb.SBEvent
    
    init(_ lldbEvent: lldb.SBEvent) {
        self.lldbEvent = lldbEvent
    }
    
    public struct EventType: OptionSet, Sendable, Hashable {
        public static let stateChanged = Self(rawValue: 1 << 0)
        public static let interrupt = Self(rawValue: 1 << 1)
        public static let standardOut = Self(rawValue: 1 << 2)
        public static let standardError = Self(rawValue: 1 << 3)
        public static let profileData = Self(rawValue: 1 << 4)
        public static let structuredData = Self(rawValue: 1 << 5)
        
        public let rawValue: UInt32
        
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
    }
    
    public var eventType: EventType {
        return EventType(rawValue: lldbEvent.GetType())
    }
    
    public var processState: Process.State {
        return Process.State(lldb.SBProcess.GetStateFromEvent(lldbEvent))
    }
    
    public var isRestarted: Bool {
        return lldb.SBProcess.GetRestartedFromEvent(lldbEvent)
    }
    
    public var isInterrupted: Bool {
        return lldb.SBProcess.GetInterruptedFromEvent(lldbEvent)
    }
    
    public var process: Process {
        return Process(unsafe: lldb.SBProcess.GetProcessFromEvent(lldbEvent))
    }
}
