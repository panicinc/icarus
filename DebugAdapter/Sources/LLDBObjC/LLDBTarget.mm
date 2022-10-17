#import "LLDBTarget.h"
#import "LLDBTarget+Private.h"
#import "LLDBDebugger+Private.h"
#import "LLDBErrors+Private.h"
#import "LLDBProcess+Private.h"

@import lldb_API;

@implementation LLDBTarget {
    lldb::SBTarget _target;
}

- (instancetype)initWithTarget:(lldb::SBTarget)target debugger:(LLDBDebugger *)debugger {
    self = [super init];
    if (self) {
        self.debugger = debugger;
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
    
    lldb::SBError error;
    lldb::SBProcess lldbProcess = _target.Launch(launchInfo, error);
    if (lldbProcess.IsValid()) {
        LLDBProcess *process = [[LLDBProcess alloc] initWithProcess:lldbProcess target:self];
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
        LLDBProcess *process = [[LLDBProcess alloc] initWithProcess:lldbProcess target:self];
        return process;
    }
    else {
        if (outError != NULL) {
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
