#import "LLDBBreakpoint+Private.h"

@implementation LLDBBreakpoint {
    lldb::SBBreakpoint _breakpoint;
}

- (instancetype)initWithBreakpoint:(lldb::SBBreakpoint)breakpoint {
    self = [super init];
    if (self) {
        _breakpoint = breakpoint;
    }
    return self;
}

- (lldb::SBBreakpoint)breakpoint {
    return _breakpoint;
}

- (uint32_t)breakpointID {
    return _breakpoint.GetID();
}

@end
