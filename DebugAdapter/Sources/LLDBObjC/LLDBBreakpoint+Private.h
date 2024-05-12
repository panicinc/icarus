#import "LLDBBreakpoint.h"

@import CLLDB;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBBreakpoint ()

- (instancetype)initWithBreakpoint:(lldb::SBBreakpoint)breakpoint NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBBreakpoint breakpoint;

@end

NS_ASSUME_NONNULL_END
