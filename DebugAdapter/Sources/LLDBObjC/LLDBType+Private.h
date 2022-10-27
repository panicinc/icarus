#import "LLDBType.h"

@import lldb_API;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBType ()

- (instancetype)initWithType:(lldb::SBType)type NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBType type;

@end

NS_ASSUME_NONNULL_END
