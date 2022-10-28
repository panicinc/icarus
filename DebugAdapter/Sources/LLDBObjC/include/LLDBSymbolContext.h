@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class LLDBCompileUnit, LLDBLineEntry;

@interface LLDBSymbolContext : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly) LLDBCompileUnit *compileUnit;
@property (readonly) LLDBLineEntry *lineEntry;

@end

NS_ASSUME_NONNULL_END
