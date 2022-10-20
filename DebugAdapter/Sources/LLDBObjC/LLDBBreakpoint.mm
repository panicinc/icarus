#import "LLDBBreakpoint+Private.h"

@implementation LLDBBreakpoint {
    lldb::SBBreakpoint _breakpoint;
}

- (instancetype)initWithBreakpoint:(lldb::SBBreakpoint)breakpoint target:(LLDBTarget *)target {
    self = [super init];
    if (self) {
        _breakpoint = breakpoint;
        self.target = target;
    }
    return self;
}

- (void)dealloc {
    
}

- (lldb::SBBreakpoint)breakpoint {
    return _breakpoint;
}

@end
