@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class LLDBPlatformDescription, LLDBCommandInterpreter, LLDBPlatform, LLDBTarget;

@interface LLDBDebugger : NSObject

+ (BOOL)initializeWithError:(NSError **)outError;
+ (void)terminate;

@property (readonly) LLDBCommandInterpreter *commandInterpreter;

// Targets
@property (copy, readonly) NSArray <LLDBTarget *> *targets;
@property (nullable) LLDBTarget *selectedTarget;
- (nullable LLDBTarget *)createTargetWithPath:(NSString *)path triple:(nullable NSString *)triple platformName:(nullable NSString *)platformName error:(NSError **)outError;
- (nullable LLDBTarget *)createTargetWithPath:(NSString *)path architecture:(nullable NSString *)architecture error:(NSError **)outError;
- (nullable LLDBTarget *)findTargetWithPath:(NSString *)path architecture:(nullable NSString *)architecture error:(NSError **)outError;
- (nullable LLDBTarget *)findTargetWithProcessIdentifier:(pid_t)pid error:(NSError **)outError;
- (BOOL)deleteTarget:(LLDBTarget *)target;

// Platforms
@property (copy, readonly) NSArray <LLDBPlatformDescription *> *availablePlatforms;

@property (nullable) LLDBPlatform *selectedPlatform;

@end

@interface LLDBPlatformDescription : NSObject

@property (nullable, copy) NSString *name;
@property (nullable, copy) NSString *descriptiveText;

@end

NS_ASSUME_NONNULL_END
