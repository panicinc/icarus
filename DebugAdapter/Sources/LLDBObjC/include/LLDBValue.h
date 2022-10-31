@import Foundation;

#import <LLDBTypes.h>

NS_ASSUME_NONNULL_BEGIN

// Equivalent to lldb::ValueType
typedef NS_ENUM(NSUInteger, LLDBValueType) {
    LLDBValueTypeInvalid,
    LLDBValueTypeVariableGlobal,
    LLDBValueTypeVariableStatic	,
    LLDBValueTypeVariableArgument,
    LLDBValueTypeVariableLocal,
    LLDBValueTypeRegister,
    LLDBValueTypeRegisterSet,
    LLDBValueTypeConstResult,
    LLDBValueTypeVariableThreadLocal,
};

@class LLDBType;

@interface LLDBValue : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (copy, readonly) NSString *name;
@property (nullable, copy, readonly) NSString *typeName;
@property (nullable, copy, readonly) NSString *displayTypeName;

@property (readonly) size_t byteSize;
@property (readonly, getter=isInScope) BOOL inScope;

@property (readonly) LLDBType *type;
@property (readonly) LLDBFormat format;
@property (readonly) LLDBValueType valueType;

@property (nullable, copy, readonly) NSString *stringValue;

@property (nullable, copy, readonly) NSString *summary;
@property (nullable, copy, readonly) NSString *objectDescription;

@property (readonly, getter=isSynthetic) BOOL synthetic;

@property (readonly) NSUInteger childCount;
- (nullable LLDBValue *)childAtIndex:(NSUInteger)idx;
@property (copy, readonly) NSArray <LLDBValue *> *children;

- (nullable LLDBValue *)childMemberWithName:(NSString *)childName;

- (BOOL)setValueFromString:(NSString *)value error:(NSError **)outError NS_SWIFT_NAME(setValue(from:));

@end

NS_ASSUME_NONNULL_END
