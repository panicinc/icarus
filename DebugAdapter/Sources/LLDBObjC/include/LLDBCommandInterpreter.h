@import Foundation;

#import <LLDBTypes.h>

NS_ASSUME_NONNULL_BEGIN

@class LLDBCommandReturnObject, LLDBExecutionContext;

@interface LLDBCommandInterpreter : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (nullable LLDBCommandReturnObject *)handleCommand:(NSString *)command addToHistory:(BOOL)addToHistory error:(NSError **)outError;
- (nullable LLDBCommandReturnObject *)handleCommand:(NSString *)command context:(LLDBExecutionContext *)context addToHistory:(BOOL)addToHistory error:(NSError **)outError;

- (NSArray <NSString *> *)handleCompletions:(NSString *)text cursorPosition:(NSUInteger)cursorPosition matchStart:(NSUInteger)matchStart maxResults:(NSUInteger)maxResults;

@end

@interface LLDBCommandReturnObject : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (nullable, copy, readonly) NSString *output;

@end

NS_ASSUME_NONNULL_END
