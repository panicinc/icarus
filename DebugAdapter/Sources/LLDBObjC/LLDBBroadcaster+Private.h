#import "LLDBBroadcaster.h"

@import lldb_API;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBBroadcaster ()

- (instancetype)initWithBroadcaster:(lldb::SBBroadcaster)broadcaster;

@property (readonly) lldb::SBBroadcaster broadcaster;

@end

NS_ASSUME_NONNULL_END
