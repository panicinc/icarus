#import "LLDBPlatform.h"

@import CLLDB;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBPlatform ()

- (instancetype)initWithPlatform:(lldb::SBPlatform)platform NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBPlatform platform;

@end

@interface LLDBPlatformConnectOptions ()

@end

NS_ASSUME_NONNULL_END

