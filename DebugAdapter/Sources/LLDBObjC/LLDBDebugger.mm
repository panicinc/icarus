#import "LLDBDebugger+Private.h"
#import "LLDBCommandInterpreter+Private.h"
#import "LLDBPlatform+Private.h"
#import "LLDBTarget+Private.h"
#import "LLDBErrors+Private.h"

@import CLLDB;

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

- (LLDBCommandInterpreter *)commandInterpreter {
    return [[LLDBCommandInterpreter alloc] initWithCommandInterpreter:_debugger.GetCommandInterpreter()];
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

- (LLDBTarget *)selectedTarget {
    lldb::SBTarget target = _debugger.GetSelectedTarget();
    if (target.IsValid()) {
        return [[LLDBTarget alloc] initWithTarget:target];
    }
    else {
        return nil;
    }
}

- (void)setSelectedTarget:(LLDBTarget *)selectedTarget {
    lldb::SBTarget target = selectedTarget.target;
    _debugger.SetSelectedTarget(target);
}

- (LLDBTarget *)createTargetWithPath:(NSString *)path triple:(NSString *)triple platformName:(NSString *)platformName error:(NSError *__autoreleasing *)outError {
    lldb::SBError error;
    lldb::SBTarget lldbTarget = _debugger.CreateTarget(path.UTF8String, triple.UTF8String, platformName.UTF8String, true, error);
    if (lldbTarget.IsValid()) {
        return [[LLDBTarget alloc] initWithTarget:lldbTarget];
    }
    else {
        if (outError != NULL) {
            *outError = [NSError lldb_errorWithLLDBError:error];
        }
        return nil;
    }
}

- (LLDBTarget *)createTargetWithPath:(NSString *)path architecture:(NSString *)architecture error:(NSError *__autoreleasing *)outError {
    const char * arch = architecture.UTF8String;
    if (arch == NULL) {
        arch = LLDB_ARCH_DEFAULT;
    }
    
    lldb::SBTarget lldbTarget = _debugger.CreateTargetWithFileAndArch(path.UTF8String, arch);
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

- (LLDBTarget *)findTargetWithPath:(NSString *)path architecture:(NSString *)architecture error:(NSError *__autoreleasing *)outError {
    const char * arch = architecture.UTF8String;
    if (arch == NULL) {
        arch = LLDB_ARCH_DEFAULT;
    }
    
    lldb::SBTarget lldbTarget = _debugger.FindTargetWithFileAndArch(path.UTF8String, arch);
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

- (NSArray <LLDBPlatformDescription *> *)availablePlatforms {
    uint32_t count = _debugger.GetNumAvailablePlatforms();
    NSMutableArray <LLDBPlatformDescription *> *availablePlatforms = [NSMutableArray arrayWithCapacity:count];
    for (uint32_t i = 0; i < count; i++) {
        lldb::SBStructuredData info = _debugger.GetAvailablePlatformInfoAtIndex(i);
        
        char nameStr[255];
        info.GetValueForKey("name").GetStringValue(nameStr, 255);
        NSString *name = @(nameStr);
        
        char descStr[255];
        info.GetValueForKey("description").GetStringValue(descStr, 255);
        NSString *description = @(descStr);
        
        LLDBPlatformDescription *availablePlatform = [LLDBPlatformDescription new];
        availablePlatform.name = name;
        availablePlatform.descriptiveText = description;
        [availablePlatforms addObject:availablePlatform];
    }
    return availablePlatforms;
}

- (LLDBPlatform *)selectedPlatform {
    lldb::SBPlatform platform = _debugger.GetSelectedPlatform();
    if (platform.IsValid()) {
        return [[LLDBPlatform alloc] initWithPlatform:platform];
    }
    else {
        return nil;
    }
}

- (void)setSelectedPlatform:(LLDBPlatform *)selectedPlatform {
    lldb::SBPlatform platform = selectedPlatform.platform;
    _debugger.SetSelectedPlatform(platform);
}

@end

@implementation LLDBPlatformDescription

@end
