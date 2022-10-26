@import Foundation;

#import <LLDBTypes.h>

NS_ASSUME_NONNULL_BEGIN

@class LLDBBreakpoint, LLDBAttachOptions, LLDBLaunchOptions, LLDBProcess;

@interface LLDBTarget : NSObject

@property (class, readonly) NSString *broadcasterClassName;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly, getter=isValid) BOOL valid;

@property (readonly) CFByteOrder byteOrder;
@property (readonly) uint32_t addressByteSize;

// Launch and attach
- (nullable LLDBProcess *)launchWithOptions:(nullable LLDBLaunchOptions *)options error:(NSError **)outError;
- (nullable LLDBProcess *)attachWithOptions:(nullable LLDBAttachOptions *)options error:(NSError **)outError;

@property (nullable, readonly) LLDBProcess *process;

// Breakpoints
- (LLDBBreakpoint *)createBreakpointForURL:(NSURL *)fileURL line:(NSNumber *)line;
- (LLDBBreakpoint *)createBreakpointForURL:(NSURL *)fileURL line:(NSNumber *)line column:(nullable NSNumber *)column offset:(nullable NSNumber *)offset moveToNearestCode:(BOOL)moveToNearestCode;

- (LLDBBreakpoint *)createBreakpointForName:(NSString *)name;

- (LLDBBreakpoint *)createBreakpointForExceptionInLanguageType:(LLDBLanguageType)languageType onCatch:(BOOL)onCatch onThrow:(BOOL)onThrow;

- (nullable LLDBBreakpoint *)findBreakpointByID:(uint32_t)breakpointID;

- (BOOL)removeBreakpointWithID:(uint32_t)breakpointID;

@end

@interface LLDBLaunchOptions : NSObject

@property (nullable, copy) NSArray <NSString *> *arguments;
@property (nullable, copy) NSDictionary <NSString *, NSString *> *environment;
@property (nullable, copy) NSURL *currentDirectoryURL;
@property BOOL stopAtEntry;

@end

@interface LLDBAttachOptions : NSObject

@property BOOL waitForLaunch;
@property BOOL stopAtEntry;

@end

NS_ASSUME_NONNULL_END
