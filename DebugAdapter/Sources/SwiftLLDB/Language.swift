import CxxLLDB

public struct Language: RawRepresentable, Sendable, Hashable {
    public static let unknown = Self(lldb.eLanguageTypeUnknown)
    
    public static let c = Self(lldb.eLanguageTypeC)
    public static let c89 = Self(lldb.eLanguageTypeC89)
    public static let c99 = Self(lldb.eLanguageTypeC99)
    public static let c11 = Self(lldb.eLanguageTypeC11)
    public static let c17 = Self(lldb.eLanguageTypeC17)
    
    public static let cxx = Self(lldb.eLanguageTypeC_plus_plus)
    public static let cxx03 = Self(lldb.eLanguageTypeC_plus_plus_03)
    public static let cxx11 = Self(lldb.eLanguageTypeC_plus_plus_11)
    public static let cxx14 = Self(lldb.eLanguageTypeC_plus_plus_14)
    public static let cxx17 = Self(lldb.eLanguageTypeC_plus_plus_17)
    public static let cxx20 = Self(lldb.eLanguageTypeC_plus_plus_20)
    
    public static let objC = Self(lldb.eLanguageTypeObjC)
    public static let objCxx = Self(lldb.eLanguageTypeObjC_plus_plus)
    
    public static let rust = Self(lldb.eLanguageTypeRust)
    
    public static let swift = Self(lldb.eLanguageTypeSwift)
    
    public static let cSharp = Self(lldb.eLanguageTypeC_sharp)
    
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    init(_ value: lldb.LanguageType) {
        self.rawValue = Int(value.rawValue)
    }
    
    var lldbLanguageType: lldb.LanguageType {
        return lldb.LanguageType(UInt32(rawValue))
    }
    
    public init?(name: String) {
        let type = lldb.SBLanguageRuntime.GetLanguageTypeFromString(name)
        guard type != lldb.eLanguageTypeUnknown else {
            return nil
        }
        self.init(type)
    }
    
    public var name: String {
        return String(cString: lldb.SBLanguageRuntime.GetNameForLanguageType(lldbLanguageType))
    }
}
