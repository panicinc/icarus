#import "LLDBCompileUnit+Private.h"
#import "LLDBFileSpec+Private.h"
#import "LLDBLineEntry+Private.h"

@implementation LLDBCompileUnit {
    lldb::SBCompileUnit _compileUnit;
}

- (instancetype)initWithCompileUnit:(lldb::SBCompileUnit)compileUnit {
    self = [super init];
    if (self) {
        _compileUnit = compileUnit;
    }
    return self;
}

- (lldb::SBCompileUnit)compileUnit {
    return _compileUnit;
}

- (LLDBFileSpec *)fileSpec {
    return [[LLDBFileSpec alloc] initWithFileSpec:_compileUnit.GetFileSpec()];
}

- (NSUInteger)lineEntryCount {
    return _compileUnit.GetNumLineEntries();
}

- (LLDBLineEntry *)lineEntryAtIndex:(NSUInteger)idx {
    lldb::SBLineEntry lineEntry = _compileUnit.GetLineEntryAtIndex((uint32_t)idx);
    if (lineEntry.IsValid()) {
        return [[LLDBLineEntry alloc] initWithLineEntry:lineEntry];
    }
    else {
        return nil;
    }
}

- (NSArray <LLDBLineEntry *> *)lineEntries {
    uint32_t count = _compileUnit.GetNumLineEntries();
    NSMutableArray <LLDBLineEntry *> *lineEntries = [NSMutableArray arrayWithCapacity:(NSUInteger)count];
    for (uint32_t i = 0; i < count; i++) {
        LLDBLineEntry *lineEntry = [[LLDBLineEntry alloc] initWithLineEntry:_compileUnit.GetLineEntryAtIndex(i)];
        [lineEntries addObject:lineEntry];
    }
    return lineEntries;
}

@end
