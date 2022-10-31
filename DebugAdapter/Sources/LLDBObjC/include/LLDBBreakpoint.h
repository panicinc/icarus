@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class LLDBBreakpointLocation, LLDBProcess, LLDBThread;

typedef BOOL (^LLDBBreakpointCallback)(LLDBProcess *process, LLDBThread *thread, LLDBBreakpointLocation *location);

@interface LLDBBreakpoint : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly) uint32_t breakpointID;

@property (nullable, copy) NSString *condition;

- (void)setCallback:(LLDBBreakpointCallback)callback;

+ (void)clearAllCallbacks;

@end

NS_ASSUME_NONNULL_END
