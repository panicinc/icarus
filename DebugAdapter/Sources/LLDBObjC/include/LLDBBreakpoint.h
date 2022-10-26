@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBBreakpoint : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly) uint32_t breakpointID;

@end

NS_ASSUME_NONNULL_END
