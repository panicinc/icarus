#import "LLDBExecutionContext+Private.h"
#import "LLDBFrame+Private.h"
#import "LLDBTarget+Private.h"
#import "LLDBThread+Private.h"

@implementation LLDBExecutionContext {
    lldb::SBExecutionContext _executionContext;
}

- (instancetype)initWithExecutionContext:(lldb::SBExecutionContext)executionContext {
    self = [super init];
    if (self) {
        _executionContext = executionContext;
    }
    return self;
}

- (lldb::SBExecutionContext)executionContext {
    return _executionContext;
}

+ (instancetype)executionContextFromFrame:(LLDBFrame *)frame {
    lldb::SBExecutionContext ctx(frame.frame);
    return [[self alloc] initWithExecutionContext:ctx];
}

+ (instancetype)executionContextFromTarget:(LLDBTarget *)target {
    lldb::SBExecutionContext ctx(target.target);
    return [[self alloc] initWithExecutionContext:ctx];
}

+ (instancetype)executionContextFromThread:(LLDBThread *)thread {
    lldb::SBExecutionContext ctx(thread.thread);
    return [[self alloc] initWithExecutionContext:ctx];
}

@end
