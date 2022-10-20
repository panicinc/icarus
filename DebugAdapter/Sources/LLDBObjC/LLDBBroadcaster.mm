#import "LLDBBroadcaster+Private.h"

@implementation LLDBBroadcaster {
    lldb::SBBroadcaster _broadcaster;
}

- (instancetype)initWithBroadcaster:(lldb::SBBroadcaster)broadcaster {
    self = [super init];
    if (self) {
        _broadcaster = broadcaster;
    }
    return self;
}

- (lldb::SBBroadcaster)broadcaster {
    return _broadcaster;
}

@end
