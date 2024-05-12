#import "LLDBDebugger.h"

@import CLLDB;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBDebugger ()

@property (readonly) lldb::SBDebugger debugger;

@end

NS_ASSUME_NONNULL_END
