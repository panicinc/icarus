#import "LLDBBreakpointLocation+Private.h"

@implementation LLDBBreakpointLocation {
    lldb::SBBreakpointLocation _breakpointLocation;
}

- (instancetype)initWithBreakpointLocation:(lldb::SBBreakpointLocation)breakpointLocation {
    self = [super init];
    if (self) {
        _breakpointLocation = breakpointLocation;
    }
    return self;
}

- (lldb::SBBreakpointLocation)breakpointLocation {
    return _breakpointLocation;
}

@end
