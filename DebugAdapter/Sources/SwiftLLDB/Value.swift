import CxxLLDB

public struct Value: Sendable {
    nonisolated(unsafe) let lldbValue: lldb.SBValue
    
    init?(_ lldbValue: lldb.SBValue) {
        var lldbValue = lldbValue
        guard lldbValue.IsValid() else {
            return nil
        }
        self.lldbValue = lldbValue
    }
    
    init(unsafe lldbValue: lldb.SBValue) {
        self.lldbValue = lldbValue
    }
}

extension Value: Identifiable {
    public var id: Int {
        var lldbValue = lldbValue
        return Int(lldbValue.GetID())
    }
}

extension Value {
    public var name: String? {
        var lldbValue = lldbValue
        return String(optionalCString: lldbValue.GetName())
    }
    
    public var dataType: DataType? {
        var lldbValue = lldbValue
        return DataType(lldbValue.GetType())
    }
    
    public var typeName: String? {
        var lldbValue = lldbValue
        return String(optionalCString: lldbValue.GetTypeName())
    }
    
    public var displayTypeName: String? {
        var lldbValue = lldbValue
        return String(optionalCString: lldbValue.GetDisplayTypeName())
    }
    
    public var byteSize: Int {
        var lldbValue = lldbValue
        return lldbValue.GetByteSize()
    }
    
    public var isInScope: Bool {
        var lldbValue = lldbValue
        return lldbValue.IsInScope()
    }
    
    public var error: String? {
        var lldbValue = lldbValue
        let error = lldbValue.GetError()
        guard error.Fail() else {
            return nil
        }
        return String(optionalCString: error.GetCString())
    }
    
    public var expressionPath: String? {
        var lldbValue = lldbValue
        var stream = lldb.SBStream()
        lldbValue.GetExpressionPath(&stream)
        return String(optionalCString: stream.GetData())
    }
    
    public var format: Format {
        get {
            var lldbValue = lldbValue
            return Format(lldbValue.GetFormat())
        }
        nonmutating set {
            var lldbValue = lldbValue
            lldbValue.SetFormat(newValue.lldbFormat)
        }
    }
    
    /// Equivalent to lldb::ValueType.
    public struct ValueType: RawRepresentable, Sendable, Hashable {
        public static let invalid = Self(lldb.eValueTypeInvalid)
        public static let global = Self(lldb.eValueTypeVariableGlobal)
        public static let `static` = Self(lldb.eValueTypeVariableStatic)
        public static let argument = Self(lldb.eValueTypeVariableArgument)
        public static let local = Self(lldb.eValueTypeVariableLocal)
        public static let register = Self(lldb.eValueTypeRegister)
        public static let registerSet = Self(lldb.eValueTypeRegisterSet)
        public static let constResult = Self(lldb.eValueTypeConstResult)
        public static let threadLocal = Self(lldb.eValueTypeVariableThreadLocal)
        
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        init(_ valueType: lldb.ValueType) {
            self.rawValue = Int(valueType.rawValue)
        }
        
        var lldbValueType: lldb.ValueType { lldb.ValueType(UInt32(rawValue)) }
    }
    
    public var valueType: ValueType {
        var lldbValue = lldbValue
        return ValueType(lldbValue.GetValueType())
    }
    
    public var value: String? {
        var lldbValue = lldbValue
        return String(optionalCString: lldbValue.GetValue())
    }
    
    public func setValue(_ string: String) throws {
        var lldbValue = lldbValue
        var error = lldb.SBError()
        lldbValue.SetValueFromCString(string, &error)
        try error.throwOnFail()
    }
    
    public func valueAsSigned() throws -> Int64 {
        var lldbValue = lldbValue
        var error = lldb.SBError()
        let value = lldbValue.GetValueAsSigned(&error)
        try error.throwOnFail()
        return value
    }
    
    public func valueAsUnsigned() throws -> UInt64 {
        var lldbValue = lldbValue
        var error = lldb.SBError()
        let value = lldbValue.GetValueAsUnsigned(&error)
        try error.throwOnFail()
        return value
    }
    
    public var valueAsAddress: UInt64? {
        var lldbValue = lldbValue
        let addr = lldbValue.GetValueAsAddress()
        guard addr != LLDB_INVALID_ADDRESS else {
            return nil
        }
        return addr
    }
    
    public var summary: String? {
        var lldbValue = lldbValue
        return String(optionalCString: lldbValue.GetSummary())
    }
    
    public var description: String? {
        var lldbValue = lldbValue
        var stream = lldb.SBStream()
        lldbValue.GetDescription(&stream)
        return String(optionalCString: stream.GetData())
    }
    
    public var objectDescription: String? {
        var lldbValue = lldbValue
        return String(optionalCString: lldbValue.GetObjectDescription())
    }
    
    public var isSynthetic: Bool {
        var lldbValue = lldbValue
        return lldbValue.IsSynthetic()
    }
    
    public var location: String? {
        var lldbValue = lldbValue
        return String(optionalCString: lldbValue.GetLocation())
    }
    
    public var mightHaveChildren: Bool {
        var lldbValue = lldbValue
        return lldbValue.MightHaveChildren()
    }
    
    public struct Children: Sendable, RandomAccessCollection {
        nonisolated(unsafe) let lldbValue: lldb.SBValue
        
        init(_ lldbValue: lldb.SBValue) {
            self.lldbValue = lldbValue
        }
        
        public var count: Int {
            var lldbValue = lldbValue
            return Int(lldbValue.GetNumChildren())
        }
        
        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { count }
        
        public subscript(position: Int) -> Value {
            var lldbValue = lldbValue
            return Value(unsafe: lldbValue.GetChildAtIndex(UInt32(position)))
        }
    }
    
    public var children: Children { Children(lldbValue) }
    
    public func childMember(named name: String) -> Value? {
        var lldbValue = lldbValue
        return Value(lldbValue.GetChildMemberWithName(name))
    }
    
    public var loadAddress: UInt64? {
        var lldbValue = lldbValue
        let addr = lldbValue.GetLoadAddress()
        guard addr != LLDB_INVALID_ADDRESS else {
            return nil
        }
        return addr
    }
    
    public func pointeeData(at index: Int = 0, count: Int = 1) -> DataBuffer? {
        var lldbValue = lldbValue
        let data = lldbValue.GetPointeeData(UInt32(index), UInt32(count))
        return DataBuffer(data)
    }
    
    public var declaration: Declaration? {
        var lldbValue = lldbValue
        return Declaration(lldbValue.GetDeclaration())
    }
}
