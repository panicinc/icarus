@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class LLDBTarget;

@interface LLDBBreakpoint : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (strong, readonly) LLDBTarget *target;

@end

NS_ASSUME_NONNULL_END
