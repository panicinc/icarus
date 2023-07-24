@import Foundation;
#include <objc/NSObject.h>

NS_ASSUME_NONNULL_BEGIN

@class LLDBLaunchOptions, LLDBPlatformConnectOptions;

@interface LLDBPlatform : NSObject

- (instancetype)initWithName:(nullable NSString *)name NS_DESIGNATED_INITIALIZER;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (nullable, copy, readonly) NSString *name;

@property (readonly, getter=isValid) BOOL valid;

@property (nullable, copy, readonly) NSString *workingDirectory;
- (BOOL)setWorkingDirectory:(NSString *)workingDirectory;

@property (nullable, copy, readonly) NSString *triple;
@property (nullable, copy, readonly) NSString *hostname;
@property (nullable, copy, readonly) NSString *OSBuild;
@property (nullable, copy, readonly) NSString *OSDescription;
@property (readonly) NSUInteger OSMajorVersion;
@property (readonly) NSUInteger OSMinorVersion;
@property (readonly) NSUInteger OSUpdateVersion;

@property (readonly, getter=isConnected) BOOL connected;
- (BOOL)connectRemote:(LLDBPlatformConnectOptions *)options error:(NSError **)outError;
- (void)disconnectRemote;

- (void)setSDKRoot:(NSString *)sdkRoot;

- (mode_t)filePermissionsForPath:(NSString *)path;
- (BOOL)setFilePermissions:(mode_t)mode forPath:(NSString *)path error:(NSError **)outError;

- (BOOL)makeDirectoryAtPath:(NSString *)path error:(NSError **)outError;

- (BOOL)launchWithOptions:(nullable LLDBLaunchOptions *)options error:(NSError **)outError;

- (BOOL)killProcessWithID:(pid_t)pid error:(NSError **)outError;

@end

@interface LLDBPlatformConnectOptions : NSObject

@property (nullable, copy) NSURL *URL;
@property (getter=isRsyncEnabled) BOOL rsyncEnabled;
@property (nullable, copy) NSString *rsyncOptions;
@property (nullable, copy) NSString *rsyncRemotePathPrefix;
@property BOOL rsyncOmitRemoteHostname;

@end

NS_ASSUME_NONNULL_END
