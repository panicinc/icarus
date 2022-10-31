#import "LLDBTarget+Private.h"
#import "LLDBBreakpoint+Private.h"
#import "LLDBDebugger+Private.h"
#import "LLDBErrors+Private.h"
#import "LLDBProcess+Private.h"
#import "LLDBValue+Private.h"

@import lldb_API;

@implementation LLDBTarget {
    lldb::SBTarget _target;
}

+ (NSString *)broadcasterClassName {
    return @(lldb::SBTarget::GetBroadcasterClassName());
}

- (instancetype)initWithTarget:(lldb::SBTarget)target {
    self = [super init];
    if (self) {
        _target = target;
    }
    return self;
}

- (lldb::SBTarget)target {
    return _target;
}

- (BOOL)isValid {
    return _target.IsValid();
}

- (CFByteOrder)byteOrder {
    lldb::ByteOrder byteOrder = _target.GetByteOrder();
    switch (byteOrder) {
    case lldb::eByteOrderBig:
        return CFByteOrderBigEndian;
    case lldb::eByteOrderLittle:
        return CFByteOrderLittleEndian;
    case lldb::eByteOrderInvalid:
    case lldb::eByteOrderPDP:
        return CFByteOrderUnknown;
    }
}

- (uint32_t)addressByteSize {
    return _target.GetAddressByteSize();
}

#pragma mark - Launch & Attach

- (LLDBProcess *)launchWithOptions:(LLDBLaunchOptions *)options error:(NSError *__autoreleasing *)outError {
    lldb::SBLaunchInfo launchInfo = _target.GetLaunchInfo();
    
    NSArray <NSString *> *arguments = options.arguments;
    if (arguments != nil) {
        __block const char ** args = (const char **)malloc(sizeof(const char *) * (arguments.count + 1));
        
        [arguments enumerateObjectsUsingBlock:^(NSString *argument, NSUInteger idx, BOOL * stop) {
            args[idx] = argument.UTF8String;
        }];
        args[arguments.count] = NULL;
        
        launchInfo.SetArguments(args, true);
        
        free(args);
    }
    
    NSDictionary <NSString *, NSString *> *environment = options.environment;
    if (environment != nil) {
        __block lldb::SBEnvironment env;
        
        [environment enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL * stop) {
            env.Set(key.UTF8String, value.UTF8String, true);
        }];
        
        launchInfo.SetEnvironment(env, true);
    }
    
    NSURL *currentDirectoryURL = options.currentDirectoryURL;
    if (currentDirectoryURL != nil) {
        launchInfo.SetWorkingDirectory(currentDirectoryURL.fileSystemRepresentation);
    }
    
    uint32_t launchFlags = launchInfo.GetLaunchFlags();
    if (options.stopAtEntry) {
        launchFlags |= lldb::eLaunchFlagStopAtEntry;
    }
    launchInfo.SetLaunchFlags(launchFlags);
    
    lldb::SBError error;
    lldb::SBProcess lldbProcess = _target.Launch(launchInfo, error);
    if (lldbProcess.IsValid()) {
        LLDBProcess *process = [[LLDBProcess alloc] initWithProcess:lldbProcess];
        return process;
    }
    else {
        if (outError != NULL) {
            *outError = [NSError lldb_errorWithLLDBError:error];
        }
        return nil;
    }
}

- (LLDBProcess *)attachWithOptions:(LLDBAttachOptions *)options error:(NSError *__autoreleasing *)outError {
    lldb::SBAttachInfo attachInfo;
    
    attachInfo.SetWaitForLaunch(options.waitForLaunch, true);
    
    lldb::SBError error;
    lldb::SBProcess lldbProcess = _target.Attach(attachInfo, error);
    if (lldbProcess.IsValid()) {
        LLDBProcess *process = [[LLDBProcess alloc] initWithProcess:lldbProcess];
        return process;
    }
    else {
        if (outError != NULL) {
            *outError = [NSError lldb_errorWithLLDBError:error];
        }
        return nil;
    }
}

- (LLDBProcess *)process {
    lldb:: SBProcess proc = _target.GetProcess();
    if (proc.IsValid()) {
        return [[LLDBProcess alloc] initWithProcess:proc];
    }
    else {
        return nil;
    }
}

#pragma mark - Breakpoints

// Breakpoints
- (LLDBBreakpoint *)createBreakpointForURL:(NSURL *)fileURL line:(NSNumber *)line {
    const char * path = fileURL.fileSystemRepresentation;
    lldb::SBBreakpoint bp = _target.BreakpointCreateByLocation(path, line.intValue);
    
    return [[LLDBBreakpoint alloc] initWithBreakpoint:bp];
}

- (LLDBBreakpoint *)createBreakpointForURL:(NSURL *)fileURL line:(NSNumber *)line column:(nullable NSNumber *)column offset:(nullable NSNumber *)offset moveToNearestCode:(BOOL)moveToNearestCode {
    const char * path = fileURL.fileSystemRepresentation;
    lldb::SBFileSpec fileSpec(path);
    lldb::SBFileSpecList moduleList;
    int lineVal = line.intValue;
    int columnVal = column.intValue;
    lldb::addr_t offsetVal = (lldb::addr_t)offset.integerValue;
    lldb::SBBreakpoint bp = _target.BreakpointCreateByLocation(fileSpec, lineVal, columnVal, offsetVal, moduleList, moveToNearestCode);
    return [[LLDBBreakpoint alloc] initWithBreakpoint:bp];
}

- (LLDBBreakpoint *)createBreakpointForName:(NSString *)name {
    const char * symbolName = name.UTF8String;
    lldb::SBBreakpoint bp = _target.BreakpointCreateByName(symbolName);
    return [[LLDBBreakpoint alloc] initWithBreakpoint:bp];
}

- (LLDBBreakpoint *)createBreakpointForExceptionInLanguageType:(LLDBLanguageType)languageType onCatch:(BOOL)onCatch onThrow:(BOOL)onThrow {
    lldb::LanguageType langtype = (lldb::LanguageType)languageType;
    lldb::SBBreakpoint bp = _target.BreakpointCreateForException(langtype, onCatch, onThrow);
    return [[LLDBBreakpoint alloc] initWithBreakpoint:bp];
}

- (LLDBBreakpoint *)findBreakpointByID:(uint32_t)breakpointID {
    lldb::SBBreakpoint bp = _target.FindBreakpointByID(breakpointID);
    if (bp.IsValid()) {
        return [[LLDBBreakpoint alloc] initWithBreakpoint:bp];
    }
    else {
        return nil;
    }
}

- (BOOL)removeBreakpointWithID:(uint32_t)breakpointID {
    return _target.BreakpointDelete(breakpointID);
}

#pragma mark - Evaluation

- (LLDBValue *)evaluateExpression:(NSString *)expression error:(NSError *__autoreleasing *)outError {
    lldb::SBValue result = _target.EvaluateExpression(expression.UTF8String);
    if (result.IsValid()) {
        return [[LLDBValue alloc] initWithValue:result];
    }
    else {
        if (outError != NULL) {
            lldb::SBError error = result.GetError();
            *outError = [NSError lldb_errorWithLLDBError:error];
        }
        return nil;
    }
}

@end

@implementation LLDBLaunchOptions

@end

@implementation LLDBAttachOptions

@end
