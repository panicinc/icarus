import CxxLLDB

public struct Format: RawRepresentable, Sendable, Hashable {
    public static let `default` = Self(lldb.eFormatDefault)
    public static let boolean = Self(lldb.eFormatBoolean)
    public static let binary = Self(lldb.eFormatBinary)
    public static let bytes = Self(lldb.eFormatBytes)
    public static let bytesWithASCII = Self(lldb.eFormatBytesWithASCII)
    public static let char = Self(lldb.eFormatChar)
    public static let charPrintable = Self(lldb.eFormatCharPrintable)
    public static let complexFloat = Self(lldb.eFormatComplexFloat)
    public static let cString = Self(lldb.eFormatCString)
    public static let decimal = Self(lldb.eFormatDecimal)
    public static let `enum` = Self(lldb.eFormatEnum)
    public static let hex = Self(lldb.eFormatHex)
    public static let hexUppercase = Self(lldb.eFormatHexUppercase)
    public static let float = Self(lldb.eFormatFloat)
    public static let octal = Self(lldb.eFormatOctal)
    public static let osType = Self(lldb.eFormatOSType)
    public static let unicode16 = Self(lldb.eFormatUnicode16)
    public static let unicode32 = Self(lldb.eFormatUnicode32)
    public static let unsigned = Self(lldb.eFormatUnsigned)
    public static let pointer = Self(lldb.eFormatPointer)
    public static let vectorOfChar = Self(lldb.eFormatVectorOfChar)
    public static let vectorOfSInt8 = Self(lldb.eFormatVectorOfSInt8)
    public static let vectorOfUInt8 = Self(lldb.eFormatVectorOfUInt8)
    public static let vectorOfSInt16 = Self(lldb.eFormatVectorOfSInt16)
    public static let vectorOfUInt16 = Self(lldb.eFormatVectorOfUInt16)
    public static let vectorOfSInt32 = Self(lldb.eFormatVectorOfSInt32)
    public static let vectorOfUInt32 = Self(lldb.eFormatVectorOfUInt32)
    public static let vectorOfSInt64 = Self(lldb.eFormatVectorOfSInt64)
    public static let vectorOfUInt64 = Self(lldb.eFormatVectorOfUInt64)
    public static let vectorOfFloat16 = Self(lldb.eFormatVectorOfFloat16)
    public static let vectorOfFloat32 = Self(lldb.eFormatVectorOfFloat32)
    public static let vectorOfFloat64 = Self(lldb.eFormatVectorOfFloat64)
    public static let vectorOfUInt128 = Self(lldb.eFormatVectorOfUInt128)
    public static let complexInteger = Self(lldb.eFormatComplexInteger)
    public static let charArray = Self(lldb.eFormatCharArray)
    public static let addressInfo = Self(lldb.eFormatAddressInfo)
    public static let hexFloat = Self(lldb.eFormatHexFloat)
    public static let instruction = Self(lldb.eFormatInstruction)
    public static let void = Self(lldb.eFormatVoid)
    public static let unicode8 = Self(lldb.eFormatUnicode8)
    
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    init(_ value: lldb.Format) {
        self.rawValue = Int(value.rawValue)
    }
    
    var lldbFormat: lldb.Format {
        return .init(rawValue: UInt32(rawValue))
    }
}
