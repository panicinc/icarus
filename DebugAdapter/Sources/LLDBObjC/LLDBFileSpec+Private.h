#import "LLDBFileSpec.h"

@import lldb_API;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBFileSpec ()

- (instancetype)initWithFileSpec:(lldb::SBFileSpec)fileSpec NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBFileSpec fileSpec;

@end

NS_ASSUME_NONNULL_END
