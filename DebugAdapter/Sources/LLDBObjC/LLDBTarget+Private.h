#import "LLDBTarget.h"

@import CLLDB;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBTarget ()

- (instancetype)initWithTarget:(lldb::SBTarget)target NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBTarget target;

@end

@interface LLDBLaunchOptions ()

@end

@interface LLDBAttachOptions ()

@end

NS_ASSUME_NONNULL_END
