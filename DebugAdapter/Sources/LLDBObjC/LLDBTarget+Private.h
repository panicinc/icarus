#import "LLDBTarget.h"
@import lldb_API;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBTarget ()

- (instancetype)initWithTarget:(lldb::SBTarget)target debugger:(LLDBDebugger *)debugger NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBTarget target;
@property (strong, readwrite) LLDBDebugger *debugger;

@end

@interface LLDBLaunchOptions ()

@end

@interface LLDBAttachOptions ()

@end

NS_ASSUME_NONNULL_END
