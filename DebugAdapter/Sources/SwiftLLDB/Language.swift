import CxxLLDB

public struct Language: RawRepresentable, Hashable {
    public static let unknown = Self(lldb.eLanguageTypeUnknown)
    public static let c89 = Self(lldb.eLanguageTypeC89)
    public static let c = Self(lldb.eLanguageTypeC)
    public static let cxx = Self(lldb.eLanguageTypeC_plus_plus)
    public static let c99 = Self(lldb.eLanguageTypeC99)
    public static let objectiveC = Self(lldb.eLanguageTypeObjC)
    public static let objectiveCxx = Self(lldb.eLanguageTypeObjC_plus_plus)
    public static let cxx03 = Self(lldb.eLanguageTypeC_plus_plus_03)
    public static let cxx11 = Self(lldb.eLanguageTypeC_plus_plus_11)
    public static let rust = Self(lldb.eLanguageTypeRust)
    public static let c11 = Self(lldb.eLanguageTypeC11)
    public static let swift = Self(lldb.eLanguageTypeSwift)
    public static let cxx14 = Self(lldb.eLanguageTypeC_plus_plus_14)
    
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    init(_ value: lldb.LanguageType) {
        self.rawValue = Int(value.rawValue)
    }
    
    var lldbLanguageType: lldb.LanguageType {
        lldb.LanguageType(UInt32(rawValue))
    }
    
    public init?(name: String) {
        let type = lldb.SBLanguageRuntime.GetLanguageTypeFromString(name)
        if type != lldb.eLanguageTypeUnknown {
            self.init(type)
        }
        else {
            return nil
        }
    }
    
    public var name: String {
        String(cString: lldb.SBLanguageRuntime.GetNameForLanguageType(lldbLanguageType))
    }
}
