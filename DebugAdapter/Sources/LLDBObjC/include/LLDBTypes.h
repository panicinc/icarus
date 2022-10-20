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

NS_ASSUME_NONNULL_END
