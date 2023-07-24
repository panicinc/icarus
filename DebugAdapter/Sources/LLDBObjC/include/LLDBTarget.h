@import Foundation;

#import <LLDBTypes.h>

NS_ASSUME_NONNULL_BEGIN

@class LLDBBreakpoint, LLDBAttachOptions, LLDBLaunchOptions, LLDBPlatform, LLDBProcess, LLDBValue;

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
@property (nullable, readonly) LLDBPlatform *platform;

// Breakpoints
- (LLDBBreakpoint *)createBreakpointForPath:(NSString *)path line:(NSNumber *)line;
- (LLDBBreakpoint *)createBreakpointForPath:(NSString *)path line:(NSNumber *)line column:(nullable NSNumber *)column offset:(nullable NSNumber *)offset moveToNearestCode:(BOOL)moveToNearestCode;

- (LLDBBreakpoint *)createBreakpointForName:(NSString *)name;

- (LLDBBreakpoint *)createBreakpointForExceptionInLanguageType:(LLDBLanguageType)languageType onCatch:(BOOL)onCatch onThrow:(BOOL)onThrow;

- (nullable LLDBBreakpoint *)findBreakpointByID:(uint32_t)breakpointID;

- (BOOL)removeBreakpointWithID:(uint32_t)breakpointID;

// Evaluation
- (nullable LLDBValue *)evaluateExpression:(NSString *)expression error:(NSError **)outError;

@end

@interface LLDBLaunchOptions : NSObject

@property (nullable, copy) NSArray <NSString *> *arguments;
@property (nullable, copy) NSDictionary <NSString *, NSString *> *environment;
@property (nullable, copy) NSString *currentDirectoryPath;
@property BOOL stopAtEntry;

@end

@interface LLDBAttachOptions : NSObject

@property pid_t processIdentifier;
@property (nullable, copy) NSString *executablePath;

@property BOOL waitForLaunch;
@property BOOL stopAtEntry;

@end

NS_ASSUME_NONNULL_END
