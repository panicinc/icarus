@import Foundation;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, LLDBThreadStopReason) {
    LLDBThreadStopReasonInvalid,
    LLDBThreadStopReasonNone,
    LLDBThreadStopReasonTrace,
    LLDBThreadStopReasonBreakpoint,
    LLDBThreadStopReasonWatchpoint,
    LLDBThreadStopReasonSignal,
    LLDBThreadStopReasonException,
    LLDBThreadStopReasonExec,
    LLDBThreadStopReasonPlanComplete,
    LLDBThreadStopReasonThreadExiting,
    LLDBThreadStopReasonInstrumentation,
    LLDBThreadStopReasonProcessorTrace,
    LLDBThreadStopReasonFork,
    LLDBThreadStopReasonVFork,
    LLDBThreadStopReasonVForkDone,
};

@class LLDBFrame;

@interface LLDBThread : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly) uint64_t threadID;
@property (readonly) uint32_t indexID;
@property (nullable, copy, readonly) NSString *name;

@property (readonly) LLDBThreadStopReason stopReason;

@property (readonly) NSUInteger stopReasonDataCount;
- (uint64_t)stopReasonDataAtIndex:(NSUInteger)idx;

@property (readonly) NSUInteger frameCount;
- (nullable LLDBFrame *)frameAtIndex:(NSUInteger)idx;
@property (copy, readonly) NSArray <LLDBFrame *> *frames;

@property (readonly) LLDBFrame *selectedFrame;
- (nullable LLDBFrame *)selectFrameAtIndex:(NSUInteger)frameIdx;

- (BOOL)stepOver:(NSError **)outError;
- (void)stepInto;
- (BOOL)stepOut:(NSError **)outError;

@end

NS_ASSUME_NONNULL_END
