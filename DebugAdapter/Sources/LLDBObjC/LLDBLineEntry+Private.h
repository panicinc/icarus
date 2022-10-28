#import "LLDBLineEntry.h"

@import lldb_API;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBLineEntry ()

- (instancetype)initWithLineEntry:(lldb::SBLineEntry)lineEntry NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBLineEntry lineEntry;

@end

NS_ASSUME_NONNULL_END
