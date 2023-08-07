#import "LLDBPlatform+Private.h"
#import "LLDBTarget+Private.h"
#import "LLDBErrors+Private.h"

@import lldb_API;

@implementation LLDBPlatform {
    lldb::SBPlatform _platform;
}

- (instancetype)initWithPlatform:(lldb::SBPlatform)platform {
    self = [super init];
    if (self) {
        _platform = lldb::SBPlatform(platform);
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        const char * nameStr = name.UTF8String;
        _platform = lldb::SBPlatform(nameStr);
    }
    return self;
}

- (lldb::SBPlatform)platform {
    return _platform;
}

- (NSString *)name {
    const char * nameStr = _platform.GetName();
    return (nameStr != NULL ? @(nameStr) : nil);
}

- (BOOL)isValid {
    return _platform.IsValid();
}

- (NSString *)workingDirectory {
    const char * str = _platform.GetWorkingDirectory();
    return (str != NULL ? @(str) : nil);
}

- (BOOL)setWorkingDirectory:(NSString *)workingDirectory {
    return _platform.SetWorkingDirectory(workingDirectory.UTF8String);
}

- (NSString *)triple {
    const char * str = _platform.GetTriple();
    return (str != NULL ? @(str) : nil);
}

- (NSString *)hostname {
    const char * str = _platform.GetHostname();
    return (str != NULL ? @(str) : nil);
}

- (NSString *)OSBuild {
    const char * str = _platform.GetOSBuild();
    return (str != NULL ? @(str) : nil);
}

- (NSUInteger)OSMajorVersion {
    return _platform.GetOSMajorVersion();
}

- (NSUInteger)OSMinorVersion {
    return _platform.GetOSMinorVersion();
}

- (NSUInteger)OSUpdateVersion {
    return _platform.GetOSUpdateVersion();
}

- (BOOL)isConnected {
    return _platform.IsConnected();
}

- (BOOL)connectRemote:(LLDBPlatformConnectOptions *)options error:(NSError *__autoreleasing *)outError {
    NSAssert(options.URL != nil, @"Options must have a URL set.");
    
    NSString *URLString = options.URL.absoluteString;
    const char * str = URLString.UTF8String;
    
    lldb::SBPlatformConnectOptions connect_options = lldb::SBPlatformConnectOptions(str);
    
    if (options.rsyncEnabled) {
        connect_options.EnableRsync(options.rsyncOptions.UTF8String, options.rsyncRemotePathPrefix.UTF8String, options.rsyncOmitRemoteHostname);
    }
    
    lldb::SBError error = _platform.ConnectRemote(connect_options);
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

- (void)disconnectRemote {
    _platform.DisconnectRemote();
}

- (mode_t)filePermissionsForPath:(NSString *)path {
    return _platform.GetFilePermissions(path.UTF8String);
}

- (BOOL)setFilePermissions:(mode_t)mode forPath:(NSString *)path error:(NSError *__autoreleasing *)outError {
    lldb::SBError error = _platform.SetFilePermissions(path.UTF8String, mode);
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

- (BOOL)makeDirectoryAtPath:(NSString *)path error:(NSError **)outError {
    lldb::SBError error = _platform.MakeDirectory(path.UTF8String);
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

- (BOOL)launchWithOptions:(LLDBLaunchOptions *)options error:(NSError *__autoreleasing *)outError {
    NSArray <NSString *> *arguments = options.arguments;
    if (arguments == nil) {
        arguments = @[];
    }
    
    __block const char ** args = (const char **)malloc(sizeof(const char *) * (arguments.count + 1));
    
    [arguments enumerateObjectsUsingBlock:^(NSString *argument, NSUInteger idx, BOOL * stop) {
        args[idx] = argument.UTF8String;
    }];
    args[arguments.count] = NULL;
    
    lldb::SBLaunchInfo launchInfo = lldb::SBLaunchInfo(args);
    
    free(args);
    
    NSDictionary <NSString *, NSString *> *environment = options.environment;
    if (environment != nil) {
        __block lldb::SBEnvironment env;
        
        [environment enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL * stop) {
            env.Set(key.UTF8String, value.UTF8String, true);
        }];
        
        launchInfo.SetEnvironment(env, true);
    }
    
    NSString *currentDirectoryPath = options.currentDirectoryPath;
    if (currentDirectoryPath != nil) {
        launchInfo.SetWorkingDirectory(currentDirectoryPath.UTF8String);
    }
    
    uint32_t launchFlags = launchInfo.GetLaunchFlags();
    if (options.stopAtEntry) {
        launchFlags |= lldb::eLaunchFlagStopAtEntry;
    }
    launchInfo.SetLaunchFlags(launchFlags);
    
    lldb::SBError error = _platform.Launch(launchInfo);
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

- (BOOL)killProcessWithID:(pid_t)pid error:(NSError *__autoreleasing *)outError {
    lldb::SBError error = _platform.Kill(pid);
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

@implementation LLDBPlatformConnectOptions

@end
