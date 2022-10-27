#import "LLDBValue+Private.h"
#import "LLDBType+Private.h"

@implementation LLDBValue {
    lldb::SBValue _value;
}

- (instancetype)initWithValue:(lldb::SBValue)value {
    self = [super init];
    if (self) {
        _value = value;
    }
    return self;
}

- (lldb::SBValue)value {
    return _value;
}

- (NSString *)name {
    return @(_value.GetName());
}

- (NSString *)typeName {
    const char * value = _value.GetTypeName();
    return (value != NULL ? @(value) : NULL);
}

- (NSString *)displayTypeName {
    const char * value = _value.GetDisplayTypeName();
    return (value != NULL ? @(value) : NULL);
}

- (size_t)byteSize {
    return _value.GetByteSize();
}

- (BOOL)isInScope {
    return _value.IsInScope();
}

- (LLDBValueType)valueType {
    return (LLDBValueType)_value.GetValueType();
}

- (LLDBFormat)format {
    return (LLDBFormat)_value.GetFormat();
}

- (LLDBType *)type {
    return [[LLDBType alloc] initWithType:_value.GetType()];
}

- (NSString *)stringValue {
    const char * value = _value.GetValue();
    return (value != NULL ? @(value) : NULL);
}

- (NSString *)summary {
    const char * value = _value.GetSummary();
    return (value != NULL ? @(value) : NULL);
}

- (NSString *)objectDescription {
    const char * value = _value.GetObjectDescription();
    return (value != NULL ? @(value) : NULL);
}

- (NSUInteger)childCount {
    return _value.GetNumChildren();
}

- (LLDBValue *)childAtIndex:(NSUInteger)idx {
    lldb::SBValue child = _value.GetChildAtIndex((uint32_t)idx);
    if (child.IsValid()) {
        return [[LLDBValue alloc] initWithValue:child];
    }
    else {
        return nil;
    }
}

- (NSArray <LLDBValue *> *)children {
    uint32_t count = _value.GetNumChildren();
    NSMutableArray <LLDBValue *> *children = [NSMutableArray arrayWithCapacity:count];
    for (uint32_t i = 0; i < count; i++) {
        LLDBValue *value = [[LLDBValue alloc] initWithValue:_value.GetChildAtIndex(i)];
        [children addObject:value];
    }
    return children;
}

@end
