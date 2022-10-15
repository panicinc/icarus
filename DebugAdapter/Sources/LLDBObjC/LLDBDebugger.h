@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class LLDBTarget;

@interface LLDBDebugger: NSObject

- (nullable LLDBTarget *)createTargetWithURL:(NSURL *)fileURL platformName:(NSString *)platformName error:(NSError **)outError;

@end

NS_ASSUME_NONNULL_END
