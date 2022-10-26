#import "LLDBFrame+Private.h"

@implementation LLDBFrame {
    lldb::SBFrame _frame;
}

- (instancetype)initWithFrame:(lldb::SBFrame)frame {
    self = [super init];
    if (self) {
        _frame = frame;
    }
    return self;
}

- (lldb::SBFrame)frame {
    return _frame;
}

- (uint32_t)frameID {
    return _frame.GetFrameID();
}

- (NSUInteger)line {
    lldb::SBLineEntry lineEntry = _frame.GetLineEntry();
    return (NSUInteger)lineEntry.GetLine();
}

- (NSUInteger)column {
    lldb::SBLineEntry lineEntry = _frame.GetLineEntry();
    return (NSUInteger)lineEntry.GetColumn();
}

- (NSURL *)fileURL {
    lldb::SBLineEntry lineEntry = _frame.GetLineEntry();
    lldb::SBFileSpec fileSpec = lineEntry.GetFileSpec();
    const char * directory = fileSpec.GetDirectory();
    const char * filename = fileSpec.GetFilename();
    if (directory != NULL && filename != NULL) {
        return [[NSURL fileURLWithPath:@(directory) isDirectory:YES] URLByAppendingPathComponent:@(filename) isDirectory:NO];
    }
    else {
        return nil;
    }
}

- (NSString *)functionName {
    const char * funcName = _frame.GetFunctionName();
    if (funcName != NULL) {
        return @(funcName);
    }
    else {
        return nil;
    }
}

- (NSString *)displayFunctionName {
    const char * funcName = _frame.GetDisplayFunctionName();
    if (funcName != NULL) {
        return @(funcName);
    }
    else {
        return nil;
    }
}

- (uint64_t)pcAddress {
    return _frame.GetPC();
}

- (BOOL)isInlined {
    return _frame.IsInlined();
}

- (BOOL)isArtificial {
    return _frame.IsArtificial();
}

@end
