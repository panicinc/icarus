#import "LLDBFrame.h"

@import lldb_API;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBFrame ()

- (instancetype)initWithFrame:(lldb::SBFrame)frame NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBFrame frame;

@end

NS_ASSUME_NONNULL_END
