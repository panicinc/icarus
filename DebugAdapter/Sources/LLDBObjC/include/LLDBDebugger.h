@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class LLDBCommandInterpreter, LLDBTarget;

@interface LLDBDebugger : NSObject

+ (BOOL)initializeWithError:(NSError **)outError;
+ (void)terminate;

@property (readonly) LLDBCommandInterpreter *commandInterpreter;

@property (copy, readonly) NSArray <LLDBTarget *> *targets;
- (nullable LLDBTarget *)createTargetWithURL:(NSURL *)fileURL architecture:(nullable NSString *)architecture error:(NSError **)outError;
- (nullable LLDBTarget *)findTargetWithURL:(NSURL *)fileURL architecture:(nullable NSString *)architecture error:(NSError **)outError;
- (nullable LLDBTarget *)findTargetWithProcessIdentifier:(pid_t)pid error:(NSError **)outError;
- (BOOL)deleteTarget:(LLDBTarget *)target;

@end

NS_ASSUME_NONNULL_END
