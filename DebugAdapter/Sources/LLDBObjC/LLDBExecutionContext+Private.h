#import "LLDBExecutionContext.h"

@import lldb_API;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBExecutionContext ()

- (instancetype)initWithExecutionContext:(lldb::SBExecutionContext)executionContext NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBExecutionContext executionContext;

@end

NS_ASSUME_NONNULL_END
