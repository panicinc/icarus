#import "LLDBThread+Private.h"
#import "LLDBFrame+Private.h"
#import "LLDBErrors+Private.h"

@implementation LLDBThread {
    lldb::SBThread _thread;
}

- (instancetype)initWithThread:(lldb::SBThread)thread {
    self = [super init];
    if (self) {
        _thread = thread;
    }
    return self;
}

- (lldb::SBThread)thread {
    return _thread;
}

- (uint64_t)threadID {
    return _thread.GetThreadID();
}

- (uint32_t)indexID {
    return _thread.GetIndexID();
}

- (NSString *)name {
    const char *nameStr = _thread.GetName();
    if (nameStr != NULL) {
        return @(nameStr);
    }
    else {
        return nil;
    }
}

- (LLDBThreadStopReason)stopReason {
    return (LLDBThreadStopReason)_thread.GetStopReason();
}

- (NSUInteger)stopReasonDataCount {
    return _thread.GetStopReasonDataCount();
}

- (uint64_t)stopReasonDataAtIndex:(NSUInteger)idx {
    return _thread.GetStopReasonDataAtIndex(idx);
}

- (NSUInteger)frameCount {
    return _thread.GetNumFrames();
}

- (LLDBFrame *)frameAtIndex:(NSUInteger)idx {
    lldb::SBFrame frame = _thread.GetFrameAtIndex((uint32_t)idx);
    if (frame.IsValid()) {
        return [[LLDBFrame alloc] initWithFrame:frame];
    }
    else {
        return nil;
    }
}

- (NSArray <LLDBFrame *> *)frames {
    uint32_t count = _thread.GetNumFrames();
    NSMutableArray <LLDBFrame *> *frames = [NSMutableArray arrayWithCapacity:count];
    for (uint32_t i = 0; i < count; i++) {
        LLDBFrame *frame = [[LLDBFrame alloc] initWithFrame:_thread.GetFrameAtIndex(i)];
        [frames addObject:frame];
    }
    return frames;
}

- (LLDBFrame *)selectedFrame {
    lldb::SBFrame frame = _thread.GetSelectedFrame();
    if (frame.IsValid()) {
        return [[LLDBFrame alloc] initWithFrame:frame];
    }
    else {
        return nil;
    }
}

- (LLDBFrame *)selectFrameAtIndex:(NSUInteger)frameIdx {
    lldb::SBFrame frame = _thread.SetSelectedFrame((uint32_t)frameIdx);
    if (frame.IsValid()) {
        return [[LLDBFrame alloc] initWithFrame:frame];
    }
    else {
        return nil;
    }
}

- (BOOL)stepOver:(NSError **)outError {
    lldb::SBError error;
    _thread.StepOver(lldb::eOnlyDuringStepping, error);
    if (error.Success()) {
        return YES;
    }
    else {
        if (outError != NULL) {
            *outError = [NSError lldb_errorWithLLDBError:error];
        }
        return NO;
    }
}

- (void)stepInto {
    _thread.StepOver(lldb::eOnlyDuringStepping);
}

- (BOOL)stepOut:(NSError **)outError {
    lldb::SBError error;
    _thread.StepOut(error);
    if (error.Success()) {
        return YES;
    }
    else {
        if (outError != NULL) {
            *outError = [NSError lldb_errorWithLLDBError:error];
        }
        return NO;
    }
}

@end
