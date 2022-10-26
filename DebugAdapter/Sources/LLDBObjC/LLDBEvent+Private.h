#import "LLDBEvent.h"

@import lldb_API;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBEvent ()

- (instancetype)initWithEvent:(lldb::SBEvent)event NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBEvent event;

@end

@interface LLDBBreakpointEvent ()

- (instancetype)initWithEvent:(lldb::SBEvent)event NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBEvent event;

@end

@interface LLDBProcessEvent ()

- (instancetype)initWithEvent:(lldb::SBEvent)event NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBEvent event;

@end

@interface LLDBTargetEvent ()

- (instancetype)initWithEvent:(lldb::SBEvent)event NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBEvent event;

@end

@interface LLDBThreadEvent ()

- (instancetype)initWithEvent:(lldb::SBEvent)event NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBEvent event;

@end

NS_ASSUME_NONNULL_END
