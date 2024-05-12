#import "LLDBListener.h"

@import CLLDB;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBListener ()

@property (readonly) lldb::SBListener listener;

@property (nullable, copy, readwrite) NSString *name;
@property (nullable, strong, readwrite) dispatch_queue_t queue;
@property (getter=isListening) BOOL listening;

@end

NS_ASSUME_NONNULL_END
