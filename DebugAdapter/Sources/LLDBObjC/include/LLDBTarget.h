@import Foundation;

#import <LLDBTypes.h>

NS_ASSUME_NONNULL_BEGIN

@class LLDBBreakpoint, LLDBDebugger, LLDBAttachOptions, LLDBLaunchOptions, LLDBProcess;

@interface LLDBTarget : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (strong, readonly) LLDBDebugger *debugger;

@property (readonly, getter=isValid) BOOL valid;

@property (readonly) CFByteOrder byteOrder;
@property (readonly) uint32_t addressByteSize;

// Launch and attach
- (nullable LLDBProcess *)launchWithOptions:(nullable LLDBLaunchOptions *)options error:(NSError **)outError;
- (nullable LLDBProcess *)attachWithOptions:(nullable LLDBAttachOptions *)options error:(NSError **)outError;

// Breakpoints
- (nullable LLDBBreakpoint *)createBreakpointForURL:(NSURL *)fileURL line:(NSNumber *)line;
- (nullable LLDBBreakpoint *)createBreakpointForURL:(NSURL *)fileURL line:(NSNumber *)line column:(nullable NSNumber *)column offset:(nullable NSNumber *)offset moveToNearestCode:(BOOL)moveToNearestCode;

- (nullable LLDBBreakpoint *)createBreakpointForName:(NSString *)name;

- (nullable LLDBBreakpoint *)createBreakpointForExceptionInLanguageType:(LLDBLanguageType)languageType onCatch:(BOOL)onCatch onThrow:(BOOL)onThrow;

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
