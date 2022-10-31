#import "LLDBCommandInterpreter.h"

@import lldb_API;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBCommandInterpreter ()

- (instancetype)initWithCommandInterpreter:(lldb::SBCommandInterpreter)commandInterpreter NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBCommandInterpreter commandInterpreter;

@end

@interface LLDBCommandReturnObject ()

- (instancetype)initWithCommandReturnObject:(lldb::SBCommandReturnObject)commandReturnObject NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBCommandReturnObject commandReturnObject;

@end

NS_ASSUME_NONNULL_END
