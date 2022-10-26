@import Foundation;
#import <LLDBProcess.h>

NS_ASSUME_NONNULL_BEGIN

@class LLDBBreakpointEvent, LLDBProcessEvent, LLDBTargetEvent, LLDBThreadEvent;

@interface LLDBEvent : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (copy, readonly) NSString *broadcasterClassName;
@property (readonly) uint32_t flags;

- (nullable LLDBBreakpointEvent *)toBreakpointEvent;
- (nullable LLDBProcessEvent *)toProcessEvent;
- (nullable LLDBTargetEvent *)toTargetEvent;
- (nullable LLDBThreadEvent *)toThreadEvent;

@end

@class LLDBBreakpoint;

typedef NS_OPTIONS(NSUInteger, LLDBBreakpointEventType) {
    LLDBBreakpointEventTypeInvalid = (1u << 0),
    LLDBBreakpointEventTypeAdded = (1u << 1),
    LLDBBreakpointEventTypeRemoved = (1u << 2),
    LLDBBreakpointEventTypeLocationsAdded = (1u << 3),
    LLDBBreakpointEventTypeLocationsRemoved = (1u << 4),
    LLDBBreakpointEventTypeLocationsResolved = (1u << 5),
    LLDBBreakpointEventTypeEnabled = (1u << 6),
    LLDBBreakpointEventTypeDisabled = (1u << 7),
    LLDBBreakpointEventTypeCommandChanged = (1u << 8),
    LLDBBreakpointEventTypeConditionChanged = (1u << 9),
    LLDBBreakpointEventTypeIgnoreChanged = (1u << 10),
    LLDBBreakpointEventTypeThreadChanged = (1u << 11),
    LLDBBreakpointEventTypeAutoContinueChanged = (1u << 12),
};

@interface LLDBBreakpointEvent : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly) LLDBBreakpoint *breakpoint;
@property (readonly) LLDBBreakpointEventType eventType;

@property (readonly) NSUInteger numberOfLocations;

@end

@class LLDBProcess;

enum: uint32_t {
    LLDBTargetEventFlagBreakpointChanged = (1 << 0),
    LLDBTargetEventFlagModulesLoaded = (1 << 1),
    LLDBTargetEventFlagModulesUnloaded = (1 << 2),
    LLDBTargetEventFlagWatchpointChanged = (1 << 3), 
    LLDBTargetEventFlagSymbolsLoaded = (1 << 4) 
};

@interface LLDBProcessEvent : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly) LLDBProcess *process;
@property (readonly) LLDBProcessState processState;
@property (readonly, getter=isRestarted) BOOL restarted;
@property (readonly, getter=isInterrupted) BOOL interrupted;

@end

@class LLDBTarget;

enum: uint32_t {
    LLDBProcessEventFlagStateChanged = (1 << 0),
    LLDBProcessEventFlagInterrupt = (1 << 1),
    LLDBProcessEventFlagSTDOUT = (1 << 2),
    LLDBProcessEventFlagSTDERR = (1 << 3),
    LLDBProcessEventFlagProfileData = (1 << 4),
    LLDBProcessEventFlagStructuredData = (1 << 5)
};

@interface LLDBTargetEvent : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly) LLDBTarget *target;

@end

@class LLDBThread, LLDBFrame;

@interface LLDBThreadEvent : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly) LLDBThread *thread;
@property (readonly) LLDBFrame *stackFrame;

@end

NS_ASSUME_NONNULL_END
