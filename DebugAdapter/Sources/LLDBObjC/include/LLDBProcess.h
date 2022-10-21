@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class LLDBBroadcaster, LLDBTarget;

typedef NS_ENUM(NSUInteger, LLDBProcessState) {
    LLDBProcessStateInvalid,
    LLDBProcessStateUnloaded,
    LLDBProcessStateConnected,
    LLDBProcessStateAttaching,
    LLDBProcessStateLaunching,
    LLDBProcessStateStopped,
    LLDBProcessStateRunning,
    LLDBProcessStateStepping,
    LLDBProcessStateCrashed,
    LLDBProcessStateDetached,
    LLDBProcessStateExited,
    LLDBProcessStateSuspended,
};

@interface LLDBProcess : NSObject

@property (class, readonly) NSString *broadcasterClassName;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly) LLDBProcessState state;

@property (readonly) pid_t processIdentifier;
@property (readonly) uint32_t uniqueIdentifier;

@property (readonly) CFByteOrder byteOrder;
@property (readonly) uint32_t addressByteSize;

@property (strong, readonly) LLDBBroadcaster *broadcaster;

@property (readonly) int exitStatus;
@property (readonly) const char * exitDescription;

- (BOOL)continue:(NSError **)outError;
- (BOOL)stop:(NSError **)outError;
- (BOOL)kill:(NSError **)outError;
- (BOOL)detach:(NSError **)outError;

- (BOOL)signal:(int)signal error:(NSError **)outError;

- (nullable NSData *)readMemoryAtAddress:(uint64_t)address size:(size_t)size error:(NSError **)outError;
- (size_t)writeMemoryAtAddress:(uint64_t)address data:(NSData *)data error:(NSError **)outError;

@end

NS_ASSUME_NONNULL_END
