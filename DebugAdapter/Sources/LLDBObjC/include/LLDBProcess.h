@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class LLDBProcessInfo, LLDBTarget, LLDBThread;

typedef NS_ENUM(NSUInteger, LLDBProcessState) {
    LLDBProcessStateInvalid = 0,
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

@property (nullable, readonly) LLDBProcessInfo *info;

@property (readonly) CFByteOrder byteOrder;
@property (readonly) uint32_t addressByteSize;

@property (readonly) NSUInteger threadCount;
- (nullable LLDBThread *)threadAtIndex:(NSUInteger)idx;
- (nullable LLDBThread *)threadWithID:(uint64_t)threadID;
- (nullable LLDBThread *)threadWithIndexID:(uint32_t)indexID;
@property (copy, readonly) NSArray <LLDBThread *> *threads;

@property (nullable, readonly) LLDBThread *selectedThread;
- (BOOL)setSelectedThread:(LLDBThread *)thread;
- (BOOL)setSelectedThreadByID:(uint64_t)threadID;
- (BOOL)setSelectedThreadByIndexID:(uint32_t)indexID;

- (NSUInteger)writeBytesToStandardIn:(const char *)bytes length:(NSUInteger)length;
- (NSUInteger)writeDataToStandardIn:(NSData *)data;

- (NSUInteger)readBytesFromStandardOut:(char *)bytes length:(NSUInteger)length;
- (nullable NSData *)readDataFromStandardOutToLength:(NSUInteger)length;

- (NSUInteger)readBytesFromStandardError:(char *)bytes length:(NSUInteger)length;
- (nullable NSData *)readDataFromStandardErrorToLength:(NSUInteger)length;

@property (readonly) int exitStatus;
@property (readonly) const char * exitDescription;

- (BOOL)resume:(NSError **)outError;
- (BOOL)stop:(NSError **)outError;
- (BOOL)kill:(NSError **)outError;
- (BOOL)detach:(NSError **)outError;

- (BOOL)signal:(int)signal error:(NSError **)outError;

- (nullable NSData *)readMemoryAtAddress:(uint64_t)address size:(size_t)size error:(NSError **)outError;
- (size_t)writeMemoryAtAddress:(uint64_t)address data:(NSData *)data error:(NSError **)outError;

@end

@interface LLDBProcessInfo : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (nullable, copy, readonly) NSString *name;
@property (nullable, copy, readonly) NSString *triple;

@property (readonly) uint32_t userID;
@property (readonly, getter=isUserIDValid) BOOL userIDValid;
@property (readonly) uint32_t groupID;
@property (readonly, getter=isGroupIDValid) BOOL groupIDValid;
@property (readonly) uint32_t effectiveUserID;
@property (readonly) uint32_t effectiveGroupID;

@end

NS_ASSUME_NONNULL_END
