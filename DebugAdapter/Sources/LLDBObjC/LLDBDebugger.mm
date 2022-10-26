#import "LLDBDebugger+Private.h"
#import "LLDBTarget+Private.h"
#import "LLDBErrors+Private.h"

@import lldb_API;

@implementation LLDBDebugger {
    lldb::SBDebugger _debugger;
}

+ (BOOL)initializeWithError:(NSError *__autoreleasing *)outError {
    lldb::SBError error = lldb::SBDebugger::InitializeWithErrorHandling();
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

+ (void)terminate {
    lldb::SBDebugger::Terminate();
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _debugger = lldb::SBDebugger::Create(false);
    }
    return self;
}

- (void)dealloc {
    lldb::SBDebugger::Destroy(_debugger);
}

- (lldb::SBDebugger)debugger {
    return _debugger;
}

- (NSArray <LLDBTarget *> *)targets {
    uint32_t count = _debugger.GetNumTargets();
    NSMutableArray <LLDBTarget *> *targets = [NSMutableArray arrayWithCapacity:count];
    for (uint32_t i = 0; i < count; i++) {
        lldb::SBTarget lldbTarget = _debugger.GetTargetAtIndex(i);
        LLDBTarget *target = [[LLDBTarget alloc] initWithTarget:lldbTarget];
        [targets addObject:target];
    }
    return targets;
}

- (LLDBTarget *)createTargetWithURL:(NSURL *)fileURL architecture:(NSString *)architecture error:(NSError *__autoreleasing *)outError {
    const char * path = fileURL.path.UTF8String;
    
    const char * arch = architecture.UTF8String;
    if (arch == NULL) {
        arch = LLDB_ARCH_DEFAULT;
    }
    
    lldb::SBTarget lldbTarget = _debugger.CreateTargetWithFileAndArch(path, arch);
    if (lldbTarget.IsValid()) {
        return [[LLDBTarget alloc] initWithTarget:lldbTarget];
    }
    else {
        if (outError != NULL) {
            *outError = [NSError lldb_errorWithDescription:@"Could not create a valid target." recoverySuggestion:nil];
        }
        return nil;
    }
}

- (LLDBTarget *)findTargetWithURL:(NSURL *)fileURL architecture:(NSString *)architecture error:(NSError *__autoreleasing *)outError {
    const char * path = fileURL.path.UTF8String;
    
    const char * arch = architecture.UTF8String;
    if (arch == NULL) {
        arch = LLDB_ARCH_DEFAULT;
    }
    
    lldb::SBTarget lldbTarget = _debugger.FindTargetWithFileAndArch(path, arch);
    if (lldbTarget.IsValid()) {
        return [[LLDBTarget alloc] initWithTarget:lldbTarget];
    }
    else {
        if (outError != NULL) {
            *outError = [NSError lldb_errorWithDescription:@"Could not find a valid target." recoverySuggestion:nil];
        }
        return nil;
    }
}

- (LLDBTarget *)findTargetWithProcessIdentifier:(pid_t)pid error:(NSError *__autoreleasing *)outError {
    lldb::SBTarget lldbTarget = _debugger.FindTargetWithProcessID(pid);
    if (lldbTarget.IsValid()) {
        return [[LLDBTarget alloc] initWithTarget:lldbTarget];
    }
    else {
        if (outError != NULL) {
            *outError = [NSError lldb_errorWithDescription:@"Could not find a valid target." recoverySuggestion:nil];
        }
        return nil;
    }
}

- (BOOL)deleteTarget:(LLDBTarget *)target {
    lldb::SBTarget lldbTarget = target.target;
    return _debugger.DeleteTarget(lldbTarget);
}

@end
