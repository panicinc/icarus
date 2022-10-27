@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class LLDBValue;

@interface LLDBValueList : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly) NSUInteger count;
- (nullable LLDBValue *)valueAtIndex:(NSUInteger)idx;
@property (copy, readonly) NSArray <LLDBValue *> *values;
- (nullable LLDBValue *)firstValueWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
