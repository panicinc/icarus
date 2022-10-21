@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class LLDBDebugger, LLDBEvent;

@interface LLDBListener : NSObject

- (instancetype)initWithName:(nullable NSString *)name queue:(nullable dispatch_queue_t)queue NS_DESIGNATED_INITIALIZER;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (nullable, copy, readonly) NSString *name;
@property (nullable, strong, readonly) dispatch_queue_t queue;

@property (nullable, copy) void (^eventHandler)(LLDBEvent *);

- (void)resume;
- (void)cancel;

- (uint32_t)startListeningInDebugger:(LLDBDebugger *)debugger eventClass:(NSString *)eventClass mask:(uint32_t)eventMask;
- (BOOL)stopListeningInDebugger:(LLDBDebugger *)debugger eventClass:(NSString *)eventClass mask:(uint32_t)eventMask;

@end

NS_ASSUME_NONNULL_END
