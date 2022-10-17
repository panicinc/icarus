@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class LLDBDebugger, LLDBAttachOptions, LLDBLaunchOptions, LLDBProcess;

@interface LLDBTarget : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (strong, readonly) LLDBDebugger *debugger;

@property (readonly, getter=isValid) BOOL valid;

@property (readonly) CFByteOrder byteOrder;
@property (readonly) uint32_t addressByteSize;

- (nullable LLDBProcess *)launchWithOptions:(nullable LLDBLaunchOptions *)options error:(NSError **)outError;
- (nullable LLDBProcess *)attachWithOptions:(nullable LLDBAttachOptions *)options error:(NSError **)outError;

@end

@interface LLDBLaunchOptions : NSObject

@property (nullable, copy) NSArray <NSString *> *arguments;
@property (nullable, copy) NSDictionary <NSString *, NSString *> *environment;
@property (nullable, copy) NSURL *currentDirectoryURL;

@end

@interface LLDBAttachOptions : NSObject

@property BOOL waitForLaunch;

@end

NS_ASSUME_NONNULL_END
