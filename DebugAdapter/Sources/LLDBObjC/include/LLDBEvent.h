@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class LLDBBreakpointEvent;
@class LLDBTargetEvent;

@interface LLDBEvent : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (copy, readonly) NSString *broadcasterClassName;
@property (readonly) uint32_t eventType;

- (nullable LLDBBreakpointEvent *)toBreakpointEvent;
- (nullable LLDBTargetEvent *)toTargetEvent;

@end

@class LLDBBreakpoint;

typedef NS_ENUM(NSUInteger, LLDBBreakpointEventType) {
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

@class LLDBTarget;

@interface LLDBTargetEvent : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly) LLDBTarget *target;

@end

@class LLDBProcess;

@interface LLDBProcessEvent : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly) LLDBProcess *process;

@end

NS_ASSUME_NONNULL_END
