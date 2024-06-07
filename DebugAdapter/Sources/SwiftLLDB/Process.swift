import Foundation
import CxxLLDB

public struct Process {
    let lldbProcess: lldb.SBProcess
    
    init(_ lldbProcess: lldb.SBProcess) {
        self.lldbProcess = lldbProcess
    }
    
    public static let broadcasterClassName = String(cString: lldb.SBProcess.GetBroadcasterClassName())
    
    public struct State: RawRepresentable, Hashable {
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
    
    public var processIdentifier: UInt64 {
        var lldbProcess = lldbProcess
        return lldbProcess.GetProcessID()
    }
    
    public struct ByteOrder: RawRepresentable, Hashable {
        /// An invalid byte order.
        public static let invalid = Self(lldb.eByteOrderInvalid)
        /// Big-endian byte order.
        public static let bigEndian = Self(lldb.eByteOrderBig)
        /// Little-endian byte order.
        public static let littleEndian = Self(lldb.eByteOrderLittle)
        
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        init(_ value: lldb.ByteOrder) {
            self.rawValue = Int(value.rawValue)
        }
    }
    
    public var byteOrder: ByteOrder {
        return ByteOrder(lldbProcess.GetByteOrder())
    }
    
    public struct Info {
        let lldbInfo: lldb.SBProcessInfo
        
        init(_ lldbInfo: lldb.SBProcessInfo) {
            self.lldbInfo = lldbInfo
        }
        
        public var processIdentifier: UInt64 {
            var lldbInfo = lldbInfo
            return lldbInfo.GetProcessID()
        }
        
        public var name: String {
            var lldbInfo = lldbInfo
            if let str = lldbInfo.GetName() {
                return String(cString: str)
            }
            else {
                return ""
            }
        }
        
        public var triple: String {
            var lldbInfo = lldbInfo
            if let str = lldbInfo.GetTriple() {
                return String(cString: str)
            }
            else {
                return ""
            }
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
    
    public var info: Info {
        var lldbProcess = lldbProcess
        return Info(lldbProcess.GetProcessInfo())
    }
    
    public var addressByteSize: Int {
        return Int(lldbProcess.GetAddressByteSize())
    }
    
    public struct Threads: RandomAccessCollection {
        let lldbProcess: lldb.SBProcess
        
        init(_ lldbProcess: lldb.SBProcess) {
            self.lldbProcess = lldbProcess
        }
        
        public var count: Int {
            var lldbProcess = lldbProcess
            return Int(lldbProcess.GetNumThreads())
        }
        
        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { count }
        @inlinable public func index(before i: Int) -> Int { i - 1 }
        @inlinable public func index(after i: Int) -> Int { i + 1 }
        
        public subscript(position: Int) -> Thread {
            var lldbProcess = lldbProcess
            return Thread(lldbProcess.GetThreadAtIndex(position))
        }
    }
    
    public var threads: Threads { Threads(lldbProcess) }
    
    public func thread(withID id: Int) -> Thread? {
        var lldbProcess = lldbProcess
        let lldbThread = lldbProcess.GetThreadByID(lldb.tid_t(id))
        if lldbThread.IsValid() {
            return Thread(lldbThread)
        }
        else {
            return nil
        }
    }
    
    public func thread(withIndexID indexID: Int) -> Thread? {
        var lldbProcess = lldbProcess
        let lldbThread = lldbProcess.GetThreadByIndexID(UInt32(indexID))
        if lldbThread.IsValid() {
            return Thread(lldbThread)
        }
        else {
            return nil
        }
    }
    
    public var selectedThread: Thread? {
        let lldbThread = lldbProcess.GetSelectedThread()
        if lldbThread.IsValid() {
            return Thread(lldbThread)
        }
        else {
            return nil
        }
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
    
    public func writeToStandardIn(_ buffer: UnsafeRawBufferPointer) -> Int {
        var lldbProcess = lldbProcess
        return lldbProcess.PutSTDIN(buffer.baseAddress, buffer.count)
    }
    
    public func writeToStandardIn(_ data: Data) -> Int {
        return data.withUnsafeBytes { buffer in
            writeToStandardIn(buffer)
        }
    }
    
    public func readFromStandardOut(into buffer: UnsafeMutableRawBufferPointer) -> Int {
        return lldbProcess.GetSTDOUT(buffer.baseAddress, buffer.count)
    }
    
    public func readFromStandardOut(count: Int) -> Data {
        var data = Data(capacity: count)
        data.count = data.withUnsafeMutableBytes { buffer in
            readFromStandardOut(into: buffer)
        }
        return data
    }
    
    public func readFromStandardError(into buffer: UnsafeMutableRawBufferPointer) -> Int {
        return lldbProcess.GetSTDERR(buffer.baseAddress, buffer.count)
    }
    
    public func readFromStandardError(count: Int) -> Data {
        var data = Data(capacity: count)
        data.count = data.withUnsafeMutableBytes { buffer in
            readFromStandardError(into: buffer)
        }
        return data
    }
    
    public var exitStatus: Int32 {
        var lldbProcess = lldbProcess
        return lldbProcess.GetExitStatus()
    }
    
    public var exitDescription: String? {
        var lldbProcess = lldbProcess
        if let str = lldbProcess.GetExitDescription() {
            return String(cString: str)
        }
        else {
            return nil
        }
    }
    
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
    
    public func readMemory(at address: UInt64, into buffer: UnsafeMutableRawBufferPointer) throws -> Int {
        var lldbProcess = lldbProcess
        var error = lldb.SBError()
        let bytesRead = lldbProcess.ReadMemory(address, buffer.baseAddress, buffer.count, &error)
        try error.throwOnFail()
        return bytesRead
    }
    
    public func readMemory(at address: UInt64, count: Int) throws -> Data {
        var data = Data(capacity: count)
        data.count = try data.withUnsafeMutableBytes { buffer in
            try readMemory(at: address, into: buffer)
        }
        return data
    }
    
    public func writeMemory(at address: UInt64, buffer: UnsafeRawBufferPointer) throws -> Int {
        var lldbProcess = lldbProcess
        var error = lldb.SBError()
        let bytesWritten = lldbProcess.WriteMemory(address, buffer.baseAddress, buffer.count, &error)
        try error.throwOnFail()
        return bytesWritten
    }
    
    public func writeMemory(at address: UInt64, data: Data) throws -> Int {
        return try data.withUnsafeBytes { buffer in
            try writeMemory(at: address, buffer: buffer)
        }
    }
}

public struct ProcessEvent {
    let lldbEvent: lldb.SBEvent
    
    init(_ lldbEvent: lldb.SBEvent) {
        self.lldbEvent = lldbEvent
    }
    
    public init?(_ event: Event) {
        let lldbEvent = event.lldbEvent
        if lldb.SBProcess.EventIsProcessEvent(lldbEvent) {
            self.init(lldbEvent)
        }
        else {
            return nil
        }
    }
    
    public struct EventFlags: OptionSet, Hashable {
        public static let stateChanged = Self(rawValue: 1 << 0)
        public static let interrupt = Self(rawValue: 1 << 1)
        public static let standardOut = Self(rawValue: 1 << 2)
        public static let standardError = Self(rawValue: 1 << 3)
        public static let profileData = Self(rawValue: 1 << 4)
        public static let structuredData = Self(rawValue: 1 << 5)
        
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    public var flags: EventFlags {
        EventFlags(rawValue: Int(lldbEvent.GetType()))
    }
    
    public var processState: Process.State {
        Process.State(lldb.SBProcess.GetStateFromEvent(lldbEvent))
    }
    
    public var isRestarted: Bool {
        lldb.SBProcess.GetRestartedFromEvent(lldbEvent)
    }
    
    public var isInterrupted: Bool {
        lldb.SBProcess.GetInterruptedFromEvent(lldbEvent)
    }
    
    public var process: Process {
        Process(lldb.SBProcess.GetProcessFromEvent(lldbEvent))
    }
}
