import CxxLLDB

public struct StructuredData: Sendable {
    let lldbStructuredData: lldb.SBStructuredData
    
    init?(_ lldbStructuredData: lldb.SBStructuredData) {
        guard lldbStructuredData.IsValid() else {
            return nil
        }
        self.lldbStructuredData = lldbStructuredData
    }
    
    init(unsafe lldbStructuredData: lldb.SBStructuredData) {
        self.lldbStructuredData = lldbStructuredData
    }
}

extension StructuredData {
    public struct DataType: RawRepresentable, Sendable, Hashable {
        public static let invalid = Self(rawValue: Int(lldb.eStructuredDataTypeInvalid.rawValue))
        public static let null = Self(rawValue: Int(lldb.eStructuredDataTypeNull.rawValue))
        public static let generic = Self(rawValue: Int(lldb.eStructuredDataTypeGeneric.rawValue))
        public static let array = Self(rawValue: Int(lldb.eStructuredDataTypeArray.rawValue))
        public static let float = Self(rawValue: Int(lldb.eStructuredDataTypeFloat.rawValue))
        public static let boolean = Self(rawValue: Int(lldb.eStructuredDataTypeBoolean.rawValue))
        public static let string = Self(rawValue: Int(lldb.eStructuredDataTypeString.rawValue))
        public static let dictionary = Self(rawValue: Int(lldb.eStructuredDataTypeDictionary.rawValue))
        public static let signedInteger = Self(rawValue: Int(lldb.eStructuredDataTypeSignedInteger.rawValue))
        public static let unsignedInteger = Self(rawValue: Int(lldb.eStructuredDataTypeUnsignedInteger.rawValue))
        
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        init(_ lldbDataType: lldb.StructuredDataType) {
            self.rawValue = Int(lldbDataType.rawValue)
        }
        
        var lldbDataType: lldb.StructuredDataType {
            return .init(rawValue: Int32(rawValue))
        }
    }
    
    public var dataType: DataType {
        return DataType(lldbStructuredData.GetType())
    }
}

extension StructuredData {
    public subscript(_ key: String) -> StructuredData? {
        return StructuredData(lldbStructuredData.GetValueForKey(key))
    }
}

extension StructuredData {
    public func asBool() -> Bool? {
        guard case .boolean = dataType else {
            return nil
        }
        return lldbStructuredData.GetBooleanValue()
    }
    
    public func asDouble() -> Double? {
        guard case .float = dataType else {
            return nil
        }
        return lldbStructuredData.GetFloatValue()
    }
    
    public func asSignedInteger() -> Int64? {
        guard case .signedInteger = dataType else {
            return nil
        }
        return lldbStructuredData.GetSignedIntegerValue()
    }
    
    public func asUnsignedInteger() -> UInt64? {
        guard case .unsignedInteger = dataType else {
            return nil
        }
        return lldbStructuredData.GetUnsignedIntegerValue()
    }
    
    public func asString() -> String? {
        withUnsafeTemporaryAllocation(of: CChar.self, capacity: 255) { buffer in
            guard lldbStructuredData.GetStringValue(buffer.baseAddress, 255) > 0 else {
                return nil
            }
            return String(cString: buffer.baseAddress!)
        }
    }
    
    public struct Items: Sendable, RandomAccessCollection {
        let lldbStructuredData: lldb.SBStructuredData
        
        init(_ lldbStructuredData: lldb.SBStructuredData) {
            self.lldbStructuredData = lldbStructuredData
        }
        
        public var count: Int { lldbStructuredData.GetSize() }
        
        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { count }
        
        public subscript(position: Int) -> StructuredData {
            return StructuredData(unsafe: lldbStructuredData.GetItemAtIndex(position))
        }
    }
    
    public var items: Items { Items(lldbStructuredData) }
}
