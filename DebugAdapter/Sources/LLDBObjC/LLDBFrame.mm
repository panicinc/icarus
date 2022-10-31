#import "LLDBFrame+Private.h"
#import "LLDBCompileUnit+Private.h"
#import "LLDBErrors+Private.h"
#import "LLDBLineEntry+Private.h"
#import "LLDBSymbolContext+Private.h"
#import "LLDBValue+Private.h"
#import "LLDBValueList+Private.h"

@implementation LLDBFrame {
    lldb::SBFrame _frame;
}

- (instancetype)initWithFrame:(lldb::SBFrame)frame {
    self = [super init];
    if (self) {
        _frame = frame;
    }
    return self;
}

- (lldb::SBFrame)frame {
    return _frame;
}

- (uint32_t)frameID {
    return _frame.GetFrameID();
}

- (LLDBLineEntry *)lineEntry {
    return [[LLDBLineEntry alloc] initWithLineEntry:_frame.GetLineEntry()];
}

- (LLDBSymbolContext *)symbolContextWithItems:(LLDBSymbolContextItem)items {
    lldb::SBSymbolContext symbolContext = _frame.GetSymbolContext((uint32_t)items);
    return [[LLDBSymbolContext alloc] initWithSymbolContext:symbolContext];
}

- (NSString *)functionName {
    const char * funcName = _frame.GetFunctionName();
    if (funcName != NULL) {
        return @(funcName);
    }
    else {
        return nil;
    }
}

- (NSString *)displayFunctionName {
    const char * funcName = _frame.GetDisplayFunctionName();
    if (funcName != NULL) {
        return @(funcName);
    }
    else {
        return nil;
    }
}

- (uint64_t)pcAddress {
    return _frame.GetPC();
}

- (BOOL)isInlined {
    return _frame.IsInlined();
}

- (BOOL)isArtificial {
    return _frame.IsArtificial();
}

- (LLDBCompileUnit *)compileUnit {
    return [[LLDBCompileUnit alloc] initWithCompileUnit:_frame.GetCompileUnit()];
}

- (LLDBValueList *)registers {
    lldb::SBValueList registers = _frame.GetRegisters();
    return [[LLDBValueList alloc] initWithValueList:registers];
}

- (LLDBValueList *)variablesWithArguments:(BOOL)arguments locals:(BOOL)locals statics:(BOOL)statics inScopeOnly:(BOOL)inScopeOnly {
    lldb::SBValueList values = _frame.GetVariables(arguments, locals, statics, inScopeOnly);
    return [[LLDBValueList alloc] initWithValueList:values];
}

- (LLDBValue *)evaluateExpression:(NSString *)expression error:(NSError *__autoreleasing *)outError {
    lldb::SBValue result = _frame.EvaluateExpression(expression.UTF8String);
    if (result.IsValid()) {
        return [[LLDBValue alloc] initWithValue:result];
    }
    else {
        if (outError != NULL) {
            lldb::SBError error = result.GetError();
            *outError = [NSError lldb_errorWithLLDBError:error];
        }
        return nil;
    }
}

- (LLDBValue *)findVariable:(NSString *)variableName {
    lldb::SBValue result = _frame.FindVariable(variableName.UTF8String);
    if (result.IsValid()) {
        return [[LLDBValue alloc] initWithValue:result];
    }
    else {
        return nil;
    }
}

@end
