@import Foundation;

NS_ASSUME_NONNULL_BEGIN

// Equivalent to lldb::TypeClass
typedef NS_OPTIONS(NSUInteger, LLDBTypeClass) {
    LLDBTypeClassInvalid = (0u),
    LLDBTypeClassArray = (1u << 0),
    LLDBTypeClassBlockPointer = (1u << 1),
    LLDBTypeClassBuiltin = (1u << 2),
    LLDBTypeClassClass = (1u << 3),
    LLDBTypeClassComplexFloat = (1u << 4),
    LLDBTypeClassComplexInteger = (1u << 5),
    LLDBTypeClassEnumeration = (1u << 6),
    LLDBTypeClassFunction = (1u << 7),
    LLDBTypeClassMemberPointer = (1u << 8),
    LLDBTypeClassObjCObject = (1u << 9),
    LLDBTypeClassObjCInterface = (1u << 10),
    LLDBTypeClassObjCObjectPointer = (1u << 11),
    LLDBTypeClassPointer = (1u << 12),
    LLDBTypeClassReference = (1u << 13),
    LLDBTypeClassStruct = (1u << 14),
    LLDBTypeClassTypedef = (1u << 15),
    LLDBTypeClassUnion = (1u << 16),
    LLDBTypeClassVector = (1u << 17),
    // Define the last type class as the MSBit of a 32 bit value
    LLDBTypeClassOther = (1u << 31),
    // Define a mask that can be used for any type when finding types
    LLDBTypeClassAny = (0xffffffffu)
};

@interface LLDBType : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly) uint64_t byteSize;

@property (readonly, getter=isPointerType) BOOL pointerType;
@property (readonly, getter=isReferenceType) BOOL referenceType;
@property (readonly, getter=isFunctionType) BOOL functionType;

@end

NS_ASSUME_NONNULL_END
