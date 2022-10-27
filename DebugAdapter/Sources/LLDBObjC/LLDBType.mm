#import "LLDBType+Private.h"

@implementation LLDBType {
    lldb::SBType _type;
}

- (instancetype)initWithType:(lldb::SBType)type {
    self = [super init];
    if (self) {
        _type = type;
    }
    return self;
}

- (lldb::SBType)type {
    return _type;
}

- (uint64_t)byteSize {
    return _type.GetByteSize();
}

- (BOOL)isPointerType {
    return _type.IsPointerType();
}

- (BOOL)isReferenceType {
    return _type.IsReferenceType();
}

- (BOOL)isFunctionType {
    return _type.IsFunctionType();
}

- (LLDBTypeClass)typeClass {
    return (LLDBTypeClass)_type.GetTypeClass();
}

@end
