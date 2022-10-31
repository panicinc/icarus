#import "LLDBCommandInterpreter+Private.h"
#import "LLDBExecutionContext+Private.h"
#import "LLDBErrors+Private.h"

@implementation LLDBCommandInterpreter {
    lldb::SBCommandInterpreter _commandInterpreter;
}

- (instancetype)initWithCommandInterpreter:(lldb::SBCommandInterpreter)commandInterpreter {
    self = [super init];
    if (self) {
        _commandInterpreter = commandInterpreter;
    }
    return self;
}

- (lldb::SBCommandInterpreter)commandInterpreter {
    return _commandInterpreter;
}

- (LLDBCommandReturnObject *)handleCommand:(NSString *)command addToHistory:(BOOL)addToHistory error:(NSError *__autoreleasing *)outError {
    lldb::SBCommandReturnObject result;
    lldb::ReturnStatus status = _commandInterpreter.HandleCommand(command.UTF8String, result, addToHistory);
    if (result.Succeeded()) {
        return [[LLDBCommandReturnObject alloc] initWithCommandReturnObject:result];
    }
    else {
        if (outError != NULL) {
            const char * error = result.GetError();
            *outError = [NSError lldb_errorWithDescription:@(error) recoverySuggestion:nil];
        }
        return nil;
    }
}

- (LLDBCommandReturnObject *)handleCommand:(NSString *)command context:(LLDBExecutionContext *)context addToHistory:(BOOL)addToHistory error:(NSError **)outError {
    lldb::SBCommandReturnObject result;
    lldb::SBExecutionContext ctx = context.executionContext;
    lldb::ReturnStatus status = _commandInterpreter.HandleCommand(command.UTF8String, ctx, result, addToHistory);
    if (result.Succeeded()) {
        return [[LLDBCommandReturnObject alloc] initWithCommandReturnObject:result];
    }
    else {
        if (outError != NULL) {
            const char * error = result.GetError();
            *outError = [NSError lldb_errorWithDescription:@(error) recoverySuggestion:nil];
        }
        return nil;
    }
}

- (NSArray <NSString *> *)handleCompletions:(NSString *)text cursorPosition:(NSUInteger)cursorPosition matchStart:(NSUInteger)matchStart maxResults:(NSUInteger)maxResults {
    lldb::SBStringList matches;
    uint32_t maxCount = (maxResults > 0 ? (uint32_t)maxResults : -1);
    int result = _commandInterpreter.HandleCompletion(text.UTF8String, (uint32_t)cursorPosition, (uint32_t)matchStart, maxCount, matches);
    if (result >= 0) {
        uint32_t count = matches.GetSize();
        NSMutableArray <NSString *> *strings = [NSMutableArray arrayWithCapacity:count];
        for (uint32_t i = 0; i < count; i++) {
            const char * str = matches.GetStringAtIndex(i);
            [strings addObject:@(str)];
        }
        return strings;
    }
    else {
        return @[];
    }
}

@end

@implementation LLDBCommandReturnObject {
    lldb::SBCommandReturnObject _commandReturnObject;
}

- (instancetype)initWithCommandReturnObject:(lldb::SBCommandReturnObject)commandReturnObject {
    self = [super init];
    if (self) {
        _commandReturnObject = commandReturnObject;
    }
    return self;
}

- (lldb::SBCommandReturnObject)commandReturnObject {
    return _commandReturnObject;
}

- (NSString *)output {
    const char * output = _commandReturnObject.GetOutput();
    return (output != NULL ? @(output) : nil);
}

@end
