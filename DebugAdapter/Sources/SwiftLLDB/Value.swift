import CxxLLDB

public struct Value {
    let lldbValue: lldb.SBValue
    
    init(_ lldbValue: lldb.SBValue) {
        self.lldbValue = lldbValue
    }
    
    public var name: String? {
        var lldbValue = lldbValue
        if let str = lldbValue.GetName() {
            return String(cString: str)
        }
        else {
            return nil
        }
    }
    
    public var typeName: String? {
        var lldbValue = lldbValue
        if let str = lldbValue.GetTypeName() {
            return String(cString: str)
        }
        else {
            return nil
        }
    }
    
    public var displayTypeName: String? {
        var lldbValue = lldbValue
        if let str = lldbValue.GetDisplayTypeName() {
            return String(cString: str)
        }
        else {
            return nil
        }
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
    public struct ValueType: RawRepresentable, Hashable {
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
        if let str = lldbValue.GetValue() {
            return String(cString: str)
        }
        else {
            return nil
        }
    }
    
    public var summary: String? {
        var lldbValue = lldbValue
        if let str = lldbValue.GetSummary() {
            return String(cString: str)
        }
        else {
            return nil
        }
    }
    
    public var objectDescription: String? {
        var lldbValue = lldbValue
        if let str = lldbValue.GetObjectDescription() {
            return String(cString: str)
        }
        else {
            return nil
        }
    }
    
    public var isSynthetic: Bool {
        var lldbValue = lldbValue
        return lldbValue.IsSynthetic()
    }
    
    public var childCount: Int {
        var lldbValue = lldbValue
        return Int(lldbValue.GetNumChildren())
    }
    
    public func child(at index: Int) -> Value {
        var lldbValue = lldbValue
        return Value(lldbValue.GetChildAtIndex(UInt32(index)))
    }
    
    public var children: [Value] {
        (0 ..< childCount).map { child(at: $0) }
    }
    
    public func childMember(withName name: String) -> Value? {
        var lldbValue = lldbValue
        var childMember = lldbValue.GetChildMemberWithName(name)
        if childMember.IsValid() {
            return Value(childMember)
        }
        else {
            return nil
        }
    }
    
    public func setValue(_ string: String) throws {
        var lldbValue = lldbValue
        var error = lldb.SBError()
        lldbValue.SetValueFromCString(string, &error)
        try error.throwOnFail()
    }
}
