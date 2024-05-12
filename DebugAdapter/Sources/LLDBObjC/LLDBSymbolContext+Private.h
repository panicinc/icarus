#import "LLDBSymbolContext.h"

@import CLLDB;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBSymbolContext ()

- (instancetype)initWithSymbolContext:(lldb::SBSymbolContext)symbolContext NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBSymbolContext symbolContext;

@end

NS_ASSUME_NONNULL_END
