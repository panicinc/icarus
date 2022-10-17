#import "LLDBListener.h"

@import lldb_API;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBListener ()

- (instancetype)initWithListener:(lldb::SBListener)listener NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBListener listener;

@end

NS_ASSUME_NONNULL_END
