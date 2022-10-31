#import "LLDBBreakpointLocation.h"

@import lldb_API;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBBreakpointLocation ()

- (instancetype)initWithBreakpointLocation:(lldb::SBBreakpointLocation)breakpointLocation NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBBreakpointLocation breakpointLocation;

@end

NS_ASSUME_NONNULL_END
