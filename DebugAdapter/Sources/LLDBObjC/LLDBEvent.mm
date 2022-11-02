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

- (uint32_t)flags {
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

- (LLDBProcessEvent *)toProcessEvent {
    lldb::SBEvent event = _event;
    if (lldb::SBProcess::EventIsProcessEvent(event)) {
        return [[LLDBProcessEvent alloc] initWithEvent:event];
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

- (LLDBThreadEvent *)toThreadEvent {
    lldb::SBEvent event = _event;
    if (lldb::SBThread::EventIsThreadEvent(event)) {
        return [[LLDBThreadEvent alloc] initWithEvent:event];
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

- (LLDBProcess *)process {
    return [[LLDBProcess alloc] initWithProcess:lldb::SBProcess::GetProcessFromEvent(_event)];
}

- (LLDBProcessState)processState {
    lldb::StateType state = lldb::SBProcess::GetStateFromEvent(_event);
    switch (state) {
    case lldb::eStateInvalid:
        return LLDBProcessStateInvalid;
    case lldb::eStateUnloaded:
        return LLDBProcessStateUnloaded;
    case lldb::eStateConnected:
        return LLDBProcessStateConnected;
    case lldb::eStateAttaching:
        return LLDBProcessStateAttaching;
    case lldb::eStateLaunching:
        return LLDBProcessStateLaunching;
    case lldb::eStateStopped:
        return LLDBProcessStateStopped;
    case lldb::eStateRunning:
        return LLDBProcessStateRunning;
    case lldb::eStateStepping:
        return LLDBProcessStateStepping;
    case lldb::eStateCrashed:
        return LLDBProcessStateCrashed;
    case lldb::eStateDetached:
        return LLDBProcessStateDetached;
    case lldb::eStateExited:
        return LLDBProcessStateExited;
    case lldb::eStateSuspended:
        return LLDBProcessStateSuspended;
    }
}

- (BOOL)isRestarted {
    return lldb::SBProcess::GetRestartedFromEvent(_event);
}

- (BOOL)isInterrupted {
    return lldb::SBProcess::GetInterruptedFromEvent(_event);
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

@implementation LLDBThreadEvent {
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
