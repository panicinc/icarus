#import "LLDBDebugger.h"
#import "LLDBTarget.h"

@import lldb_API;

using namespace lldb;

@implementation LLDBDebugger {
    SBDebugger * _debugger;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _debugger = new SBDebugger();
    }
    return self;
}

- (void)dealloc {
    delete _debugger;
}

- (LLDBTarget *)createTargetWithURL:(NSURL *)fileURL platformName:(NSString *)platformName error:(NSError *__autoreleasing *)outError {
    
    return nil;
}

@end
