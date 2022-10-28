@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class LLDBFileSpec;

@interface LLDBLineEntry : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly) NSUInteger line;
@property (readonly) NSUInteger column;

@property (readonly) LLDBFileSpec *fileSpec;

@end

NS_ASSUME_NONNULL_END
