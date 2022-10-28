#import "LLDBCompileUnit.h"

@import lldb_API;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBCompileUnit ()

- (instancetype)initWithCompileUnit:(lldb::SBCompileUnit)compileUnit NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBCompileUnit compileUnit;

@end

NS_ASSUME_NONNULL_END
