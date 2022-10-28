#import "LLDBLineEntry+Private.h"
#import "LLDBFileSpec+Private.h"

@implementation LLDBLineEntry {
    lldb::SBLineEntry _lineEntry;
}

- (instancetype)initWithLineEntry:(lldb::SBLineEntry)lineEntry {
    self = [super init];
    if (self) {
        _lineEntry = lineEntry;
    }
    return self;
}

- (lldb::SBLineEntry)lineEntry {
    return _lineEntry;
}

- (NSUInteger)line {
    return (NSUInteger)_lineEntry.GetLine();
}

- (NSUInteger)column {
    return (NSUInteger)_lineEntry.GetColumn();
}

- (LLDBFileSpec *)fileSpec {
    return [[LLDBFileSpec alloc] initWithFileSpec:_lineEntry.GetFileSpec()];
}

@end
