@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBFileSpec : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (nullable, copy, readonly) NSString *directory;
@property (nullable, copy, readonly) NSString *filename;

@property (nullable, copy, readonly) NSURL *fileURL;

@end

NS_ASSUME_NONNULL_END
