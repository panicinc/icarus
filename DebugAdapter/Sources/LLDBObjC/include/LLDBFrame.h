@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBFrame : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly) uint32_t frameID;

@property (readonly) NSUInteger line;
@property (readonly) NSUInteger column;
@property (nullable, readonly) NSURL *fileURL;

@property (nullable, copy, readonly) NSString *functionName;
@property (nullable, copy, readonly) NSString *displayFunctionName;

@property (readonly) uint64_t pcAddress;

@property (readonly, getter=isInlined) BOOL inlined;
@property (readonly, getter=isArtificial) BOOL artificial;

@end

NS_ASSUME_NONNULL_END
