import CxxLLDB

public struct ByteOrder: RawRepresentable, Sendable, Hashable {
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
    
    var lldbByteOrder: lldb.ByteOrder {
        return .init(rawValue: UInt32(rawValue))
    }
}
