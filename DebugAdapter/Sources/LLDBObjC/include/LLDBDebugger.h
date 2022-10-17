@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class LLDBTarget;

@interface LLDBDebugger : NSObject

@property (copy, readonly) NSArray <LLDBTarget *> *targets;
- (nullable LLDBTarget *)createTargetWithURL:(NSURL *)fileURL architecture:(nullable NSString *)architecture error:(NSError **)outError;
- (nullable LLDBTarget *)findTargetWithURL:(NSURL *)fileURL architecture:(nullable NSString *)architecture error:(NSError **)outError;
- (nullable LLDBTarget *)findTargetWithProcessIdentifier:(pid_t)pid error:(NSError **)outError;
- (BOOL)deleteTarget:(LLDBTarget *)target;

@end

NS_ASSUME_NONNULL_END
