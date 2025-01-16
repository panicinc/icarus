import CxxLLDB

public struct Value: Sendable {
    let lldbValue: lldb.SBValue
    
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
        return Int(lldbValue.GetByteSize())
    }
    
    public var isInScope: Bool {
        var lldbValue = lldbValue
        return lldbValue.IsInScope()
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
    
    public var summary: String? {
        var lldbValue = lldbValue
        return String(optionalCString: lldbValue.GetSummary())
    }
    
    public var objectDescription: String? {
        var lldbValue = lldbValue
        return String(optionalCString: lldbValue.GetObjectDescription())
    }
    
    public var isSynthetic: Bool {
        var lldbValue = lldbValue
        return lldbValue.IsSynthetic()
    }
    
    public struct Children: Sendable, RandomAccessCollection {
        let lldbValue: lldb.SBValue
        
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
}
