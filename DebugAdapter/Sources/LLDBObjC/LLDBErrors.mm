#import "LLDBErrors+Private.h"

NSErrorDomain const LLDBErrorDomain = @"LLDBErrorDomain";

@implementation NSError (LLDBErrors)

+ (instancetype)lldb_errorWithLLDBError:(lldb::SBError)error {
    const uint32_t errorCode = error.GetError();
    const char * message = error.GetCString();
    
    NSMutableDictionary <NSErrorUserInfoKey, id> *userInfo = [NSMutableDictionary dictionary];
    if (message != NULL) {
        userInfo[NSLocalizedDescriptionKey] = @(message);
    }
    
    return [[[self class] alloc] initWithDomain:LLDBErrorDomain code:errorCode userInfo:userInfo];
}

+ (instancetype)lldb_errorWithDescription:(NSString *)description recoverySuggestion:(NSString *)recoverySuggestion {
    NSMutableDictionary <NSErrorUserInfoKey, id> *userInfo = [NSMutableDictionary dictionary];
    userInfo[NSLocalizedDescriptionKey] = description;
    userInfo[NSLocalizedRecoverySuggestionErrorKey] = description;
    return [NSError errorWithDomain:LLDBErrorDomain code:lldb::eErrorTypeInvalid userInfo:userInfo];
}

@end
