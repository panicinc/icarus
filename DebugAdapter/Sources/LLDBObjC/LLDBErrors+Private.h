#import "LLDBErrors.h"

@import CLLDB;

NS_ASSUME_NONNULL_BEGIN

@interface NSError (LLDBErrors)

+ (instancetype)lldb_errorWithLLDBError:(lldb::SBError)error;
+ (instancetype)lldb_errorWithDescription:(NSString *)description recoverySuggestion:(nullable NSString *)recoverySuggestion;

@end

NS_ASSUME_NONNULL_END
