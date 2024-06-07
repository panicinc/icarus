import CxxLLDB

public struct Architecture: RawRepresentable, Hashable, ExpressibleByStringLiteral {
    /// Architecture of the host platform.
    public static let system = Self(rawValue: LLDB_ARCH_DEFAULT)
    /// 32-bit variant of the architecture of the host platform.
    public static let system32 = Self(rawValue: LLDB_ARCH_DEFAULT_32BIT)
    /// 64-bit variant of the architecture of the host platform.
    public static let system64 = Self(rawValue: LLDB_ARCH_DEFAULT_64BIT)
    
    /// arm64
    public static let arm64: Self = "arm64"
    /// x86_64/amd64
    public static let x86_64: Self = "x86_64"
    /// x86
    public static let x86: Self = "x86"
    
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(stringLiteral: String) {
        self.rawValue = stringLiteral
    }
}
