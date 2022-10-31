@import Foundation;

NS_ASSUME_NONNULL_BEGIN

// Equivalent to lldb::LanguageType
typedef NS_ENUM(NSUInteger, LLDBLanguageType) {
    LLDBLanguageTypeC89 = 0x0001,
    LLDBLanguageTypeC = 0x0002,
    LLDBLanguageTypeCPlusPlus = 0x0004,
    LLDBLanguageTypeC99 = 0x000c,
    LLDBLanguageTypeObjectiveC = 0x0010,
    LLDBLanguageTypeObjectiveCPlusPlus = 0x0011,
    LLDBLanguageTypeCPlusPlus03 = 0x0019,
    LLDBLanguageTypeCPlusPlus11 = 0x001a,
    LLDBLanguageTypeC11 = 0x001d,
    LLDBLanguageTypeSwift = 0x001e,
    LLDBLanguageTypeCPlusPlus14 = 0x0021,
};

// Equivalent to lldb::InstrumentationRuntimeType
typedef NS_ENUM(NSUInteger, LLDBInstrumentationRuntimeType) {
    LLDBInstrumentationRuntimeTypeAddressSanitizer = 0x0000,
    LLDBInstrumentationRuntimeTypeThreadSantitizer = 0x0001,
    LLDBInstrumentationRuntimeTypeUndefinedBehaviorSantitizer = 0x0002,
    LLDBInstrumentationRuntimeTypeMainThreadChecker = 0x0003,
    LLDBInstrumentationRuntimeTypeSwiftRuntimeReporting = 0x0004,
};

// Equivalent to lldb::Format
typedef NS_ENUM(NSUInteger, LLDBFormat) {
    LLDBFormatDefault,
    LLDBFormatBoolean,
    LLDBFormatBinary,
    LLDBFormatBytes,
    LLDBFormatBytesWithASCII,
    LLDBFormatChar,
    LLDBFormatCharPrintable,
    LLDBFormatComplex,
    LLDBFormatComplexFloat,
    LLDBFormatCString,
    LLDBFormatDecimal,
    LLDBFormatEnum,
    LLDBFormatHex,
    LLDBFormatHexUppercase,
    LLDBFormatFloat,
    LLDBFormatOctal,
    LLDBFormatOSType,
    LLDBFormatUnicode16,
    LLDBFormatUnicode32,
    LLDBFormatUnsigned,
    LLDBFormatPointer,
    LLDBFormatVectorOfChar,
    LLDBFormatVectorOfSInt8,
    LLDBFormatVectorOfUInt8,
    LLDBFormatVectorOfSInt16,
    LLDBFormatVectorOfUInt16,
    LLDBFormatVectorOfSInt32,
    LLDBFormatVectorOfUInt32,
    LLDBFormatVectorOfSInt64,
    LLDBFormatVectorOfUInt64,
    LLDBFormatVectorOfFloat16,
    LLDBFormatVectorOfFloat32,
    LLDBFormatVectorOfFloat64,
    LLDBFormatVectorOfUInt128,
    LLDBFormatComplexInteger,
    LLDBFormatCharArray,
    LLDBFormatAddressInfo,
    LLDBFormatHexFloat,
    LLDBFormatInstruction,
    LLDBFormatVoid,
    LLDBFormatUnicode8,
};

// Equivalent to lldb::ReturnStatus
typedef NS_ENUM(NSUInteger, LLDBReturnStatus) {
    LLDBReturnStatusInvalid,
    LLDBReturnStatusSuccessFinishNoResult,
    LLDBReturnStatusSuccessFinishResult,
    LLDBReturnStatusSuccessContinuingNoResult,
    LLDBReturnStatusSuccessContinuingResult,
    LLDBReturnStatusStarted,
    LLDBReturnStatusFailed,
    LLDBReturnStatusQuit,
};

NS_ASSUME_NONNULL_END
