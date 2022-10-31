@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class LLDBFrame, LLDBTarget, LLDBThread;

@interface LLDBExecutionContext : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)executionContextFromFrame:(LLDBFrame *)frame;
+ (instancetype)executionContextFromTarget:(LLDBTarget *)target;
+ (instancetype)executionContextFromThread:(LLDBThread *)thread;

@end

NS_ASSUME_NONNULL_END
