#import "LLDBProcess.h"

@import lldb_API;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBProcess ()

- (instancetype)initWithProcess:(lldb::SBProcess)process NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBProcess process;

@end

NS_ASSUME_NONNULL_END
