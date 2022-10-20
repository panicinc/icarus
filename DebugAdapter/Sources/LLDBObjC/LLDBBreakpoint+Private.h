#import "LLDBBreakpoint.h"
@import lldb_API;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBBreakpoint ()

- (instancetype)initWithBreakpoint:(lldb::SBBreakpoint)breakpoint target:(LLDBTarget *)target NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBBreakpoint breakpoint;
@property (strong, readwrite) LLDBTarget *target;

@end

NS_ASSUME_NONNULL_END
