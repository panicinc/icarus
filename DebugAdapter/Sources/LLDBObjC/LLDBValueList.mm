#import "LLDBValueList+Private.h"
#import "LLDBValue+Private.h"

@implementation LLDBValueList {
    lldb::SBValueList _valueList;
}

- (instancetype)initWithValueList:(lldb::SBValueList)valueList {
    self = [super init];
    if (self) {
        _valueList = valueList;
    }
    return self;
}

- (lldb::SBValueList)valueList {
    return _valueList;
}

- (NSUInteger)count {
    return _valueList.GetSize();
}

- (LLDBValue *)valueAtIndex:(NSUInteger)idx {
    lldb::SBValue value = _valueList.GetValueAtIndex((uint32_t)idx);
    if (value.IsValid()) {
        return [[LLDBValue alloc] initWithValue:value];
    }
    else {
        return nil;
    }
}

- (NSArray <LLDBValue *> *)values {
    uint32_t count = _valueList.GetSize();
    NSMutableArray <LLDBValue *> *values = [NSMutableArray arrayWithCapacity:count];
    for (uint32_t i = 0; i < count; i++) {
        LLDBValue *value = [[LLDBValue alloc] initWithValue:_valueList.GetValueAtIndex(i)];
        [values addObject:value];
    }
    return values;
}

- (LLDBValue *)firstValueWithName:(NSString *)name {
    lldb::SBValue value = _valueList.GetFirstValueByName(name.UTF8String);
    if (value.IsValid()) {
        return [[LLDBValue alloc] initWithValue:value];
    }
    else {
        return nil;
    }
}

@end
