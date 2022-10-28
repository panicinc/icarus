#import "LLDBSymbolContext+Private.h"
#import "LLDBCompileUnit+Private.h"
#import "LLDBLineEntry+Private.h"

@implementation LLDBSymbolContext {
    lldb::SBSymbolContext _symbolContext;
}

- (instancetype)initWithSymbolContext:(lldb::SBSymbolContext)symbolContext {
    self = [super init];
    if (self) {
        _symbolContext = symbolContext;
    }
    return self;
}

- (lldb::SBSymbolContext)symbolContext {
    return _symbolContext;
}

- (LLDBCompileUnit *)compileUnit {
    return [[LLDBCompileUnit alloc] initWithCompileUnit:_symbolContext.GetCompileUnit()];
}

- (LLDBLineEntry *)lineEntry {
    return [[LLDBLineEntry alloc] initWithLineEntry:_symbolContext.GetLineEntry()];
}

@end
