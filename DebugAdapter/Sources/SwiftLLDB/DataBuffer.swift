import CxxLLDB

public struct DataBuffer: Sendable {
    nonisolated(unsafe) let lldbData: lldb.SBData
    
    init?(_ lldbData: lldb.SBData) {
        var lldbData = lldbData
        guard lldbData.IsValid() else {
            return nil
        }
        self.lldbData = lldbData
    }
    
    init(unsafe lldbData: lldb.SBData) {
        self.lldbData = lldbData
    }
    
    public var byteOrder: ByteOrder {
        get {
            var lldbData = lldbData
            return ByteOrder(lldbData.GetByteOrder())
        }
        set {
            var lldbData = lldbData
            lldbData.SetByteOrder(newValue.lldbByteOrder)
        }
    }
    
    public var byteSize: Int {
        var lldbData = lldbData
        return lldbData.GetByteSize()
    }
}

extension DataBuffer: RandomAccessCollection {
    public var count: Int {
        var lldbData = lldbData
        return lldbData.GetByteSize()
    }
    
    public var startIndex: Int { 0 }
    public var endIndex: Int { count }
    
    public subscript(position: Int) -> UInt8 {
        var lldbData = lldbData
        var error = lldb.SBError()
        return lldbData.GetUnsignedInt8(&error, lldb.offset_t(position))
    }
}

extension DataBuffer {
    public func read(atByteOffset byteOffset: Int = 0, as type: Float.Type) throws -> Float {
        var lldbData = lldbData
        var error = lldb.SBError()
        let value = lldbData.GetFloat(&error, lldb.offset_t(byteOffset))
        try error.throwOnFail()
        return value
    }
    
    public func read(atByteOffset byteOffset: Int = 0, as type: Double.Type) throws -> Double {
        var lldbData = lldbData
        var error = lldb.SBError()
        let value = lldbData.GetDouble(&error, lldb.offset_t(byteOffset))
        try error.throwOnFail()
        return value
    }
    
    public func read(atByteOffset byteOffset: Int = 0, as type: Int8.Type) throws -> Int8 {
        var lldbData = lldbData
        var error = lldb.SBError()
        let value = lldbData.GetSignedInt8(&error, lldb.offset_t(byteOffset))
        try error.throwOnFail()
        return value
    }
    
    public func read(atByteOffset byteOffset: Int = 0, as type: Int16.Type) throws -> Int16 {
        var lldbData = lldbData
        var error = lldb.SBError()
        let value = lldbData.GetSignedInt16(&error, lldb.offset_t(byteOffset))
        try error.throwOnFail()
        return value
    }
    
    public func read(atByteOffset byteOffset: Int = 0, as type: Int32.Type) throws -> Int32 {
        var lldbData = lldbData
        var error = lldb.SBError()
        let value = lldbData.GetSignedInt32(&error, lldb.offset_t(byteOffset))
        try error.throwOnFail()
        return value
    }
    
    public func read(atByteOffset byteOffset: Int = 0, as type: Int64.Type) throws -> Int64 {
        var lldbData = lldbData
        var error = lldb.SBError()
        let value = lldbData.GetSignedInt64(&error, lldb.offset_t(byteOffset))
        try error.throwOnFail()
        return value
    }
    
    public func read(atByteOffset byteOffset: Int = 0, as type: UInt8.Type) throws -> UInt8 {
        var lldbData = lldbData
        var error = lldb.SBError()
        let value = lldbData.GetUnsignedInt8(&error, lldb.offset_t(byteOffset))
        try error.throwOnFail()
        return value
    }
    
    public func read(atByteOffset byteOffset: Int = 0, as type: UInt16.Type) throws -> UInt16 {
        var lldbData = lldbData
        var error = lldb.SBError()
        let value = lldbData.GetUnsignedInt16(&error, lldb.offset_t(byteOffset))
        try error.throwOnFail()
        return value
    }
    
    public func read(atByteOffset byteOffset: Int = 0, as type: UInt32.Type) throws -> UInt32 {
        var lldbData = lldbData
        var error = lldb.SBError()
        let value = lldbData.GetUnsignedInt32(&error, lldb.offset_t(byteOffset))
        try error.throwOnFail()
        return value
    }
    
    public func read(atByteOffset byteOffset: Int = 0, as type: UInt64.Type) throws -> UInt64 {
        var lldbData = lldbData
        var error = lldb.SBError()
        let value = lldbData.GetUnsignedInt64(&error, lldb.offset_t(byteOffset))
        try error.throwOnFail()
        return value
    }
}
