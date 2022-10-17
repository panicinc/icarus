#import "LLDBListener+Private.h"

@import lldb_API;

@implementation LLDBListener {
    lldb::SBListener _listener;
}

- (instancetype)initWithListener:(lldb::SBListener)listener {
    self = [super init];
    if (self) {
        _listener = listener;
    }
    return self;
}

- (lldb::SBListener)listener {
    return _listener;
}

@end
