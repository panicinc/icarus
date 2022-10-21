#import "LLDBEvent+Private.h"
#import "LLDBBreakpoint+Private.h"
#import "LLDBTarget+Private.h"
#import "LLDBProcess+Private.h"

@implementation LLDBEvent {
    lldb::SBEvent _event;
}

- (instancetype)initWithEvent:(lldb::SBEvent)event {
    self = [super init];
    if (self) {
        _event = event;
    }
    return self;
}

- (lldb::SBEvent)event {
    return _event;
}

- (NSString *)broadcasterClassName {
    return @(_event.GetBroadcasterClass());
}

- (uint32_t)eventType {
    return _event.GetType();
}

- (LLDBBreakpointEvent *)toBreakpointEvent {
    lldb::SBEvent event = _event;
    if (lldb::SBBreakpoint::EventIsBreakpointEvent(event)) {
        return [[LLDBBreakpointEvent alloc] initWithEvent:event];
    }
    else {
        return nil;
    }
}

- (LLDBTargetEvent *)toTargetEvent {
    lldb::SBEvent event = _event;
    if (lldb::SBTarget::EventIsTargetEvent(event)) {
        return [[LLDBTargetEvent alloc] initWithEvent:event];
    }
    else {
        return nil;
    }
}

- (LLDBProcessEvent *)toProcessEvent {
    lldb::SBEvent event = _event;
    if (lldb::SBProcess::EventIsProcessEvent(event)) {
        return [[LLDBProcessEvent alloc] initWithEvent:event];
    }
    else {
        return nil;
    }
}

@end

@implementation LLDBBreakpointEvent {
    lldb::SBEvent _event;
}

- (instancetype)initWithEvent:(lldb::SBEvent)event {
    self = [super init];
    if (self) {
        _event = event;
    }
    return self;
}

- (lldb::SBEvent)event {
    return _event;
}

- (LLDBBreakpoint *)breakpoint {
    return [[LLDBBreakpoint alloc] initWithBreakpoint:lldb::SBBreakpoint::GetBreakpointFromEvent(_event)];
}

- (LLDBBreakpointEventType)eventType {
    return (LLDBBreakpointEventType)lldb::SBBreakpoint::GetBreakpointEventTypeFromEvent(_event);
}

- (NSUInteger)numberOfLocations {
    return (NSUInteger)lldb::SBBreakpoint::GetNumBreakpointLocationsFromEvent(_event);
}

@end

@implementation LLDBTargetEvent {
    lldb::SBEvent _event;
}

- (instancetype)initWithEvent:(lldb::SBEvent)event {
    self = [super init];
    if (self) {
        _event = event;
    }
    return self;
}

- (lldb::SBEvent)event {
    return _event;
}

- (LLDBTarget *)target {
    return [[LLDBTarget alloc] initWithTarget:lldb::SBTarget::GetTargetFromEvent(_event)];
}

@end

@implementation LLDBProcessEvent {
    lldb::SBEvent _event;
}

- (instancetype)initWithEvent:(lldb::SBEvent)event {
    self = [super init];
    if (self) {
        _event = event;
    }
    return self;
}

- (lldb::SBEvent)event {
    return _event;
}

@end
