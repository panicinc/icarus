#import "LLDBThread.h"

@import lldb_API;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBThread ()

- (instancetype)initWithThread:(lldb::SBThread)thread NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBThread thread;

@end

NS_ASSUME_NONNULL_END
