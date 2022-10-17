#import "LLDBProcess.h"

@import lldb_API;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBProcess ()

- (instancetype)initWithProcess:(lldb::SBProcess)process target:(LLDBTarget *)target NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBProcess process;
@property (strong, readwrite) LLDBTarget *target;

@end

NS_ASSUME_NONNULL_END
