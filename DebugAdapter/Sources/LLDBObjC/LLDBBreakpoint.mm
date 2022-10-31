#import "LLDBBreakpoint+Private.h"
#import "LLDBBreakpointLocation+Private.h"
#import "LLDBProcess+Private.h"
#import "LLDBThread+Private.h"

#import <pthread.h>
#import <Block.h>

@implementation LLDBBreakpoint {
    lldb::SBBreakpoint _breakpoint;
}

static NSMapTable * __breakpoint_cb_infos = NULL;
static pthread_rwlock_t __breakpoint_cb_infos_lock;

+ (void)initialize {
    if (self == [LLDBBreakpoint class]) {
        NSPointerFunctions *keyFunctions = [NSPointerFunctions pointerFunctionsWithOptions:(NSPointerFunctionsIntegerPersonality|NSPointerFunctionsOpaqueMemory)];
        NSPointerFunctions *valueFunctions = [NSPointerFunctions pointerFunctionsWithOptions:(NSPointerFunctionsOpaquePersonality|NSPointerFunctionsMallocMemory)];
        valueFunctions.relinquishFunction = breakpoint_cb_info_free;
        __breakpoint_cb_infos = [[NSMapTable alloc] initWithKeyPointerFunctions:keyFunctions valuePointerFunctions:valueFunctions capacity:0];
        pthread_rwlock_init(&__breakpoint_cb_infos_lock, NULL);
    }
}

- (instancetype)initWithBreakpoint:(lldb::SBBreakpoint)breakpoint {
    self = [super init];
    if (self) {
        _breakpoint = breakpoint;
    }
    return self;
}

- (lldb::SBBreakpoint)breakpoint {
    return _breakpoint;
}

- (uint32_t)breakpointID {
    return _breakpoint.GetID();
}

- (NSString *)condition {
    const char * condition = _breakpoint.GetCondition();
    return (condition != NULL ? @(condition) : nil);
}

- (void)setCondition:(NSString *)condition {
    _breakpoint.SetCondition(condition.UTF8String);
}

struct breakpoint_cb_info {
    void * callback;
};

bool breakpoint_cb_thunk(void * baton, lldb::SBProcess &process, lldb::SBThread &thread, lldb::SBBreakpointLocation &location) {
    bool result = true;
    uint32_t id = location.GetBreakpoint().GetID();
    
    pthread_rwlock_rdlock(&__breakpoint_cb_infos_lock);
    
    struct breakpoint_cb_info * info = (struct breakpoint_cb_info *)NSMapGet(__breakpoint_cb_infos, &id);
    LLDBProcess *p = [[LLDBProcess alloc] initWithProcess:process];
    LLDBThread *t = [[LLDBThread alloc] initWithThread:thread];
    LLDBBreakpointLocation *bl = [[LLDBBreakpointLocation alloc] initWithBreakpointLocation:location];
    
    LLDBBreakpointCallback cb = (__bridge LLDBBreakpointCallback)(info->callback);
    result = (bool)cb(p, t, bl);
    
    pthread_rwlock_unlock(&__breakpoint_cb_infos_lock);
    
    return result;
}

void breakpoint_cb_info_free(const void * item, NSUInteger (*size)(const void *item)) {
    if (item == NULL) {
        return;
    }
    struct breakpoint_cb_info * info = (struct breakpoint_cb_info *)item;
    Block_release(info->callback);
    free(info);
}

- (void)setCallback:(LLDBBreakpointCallback)callback {
    pthread_rwlock_wrlock(&__breakpoint_cb_infos_lock);
    
    uint32_t id = _breakpoint.GetID();
    
    struct breakpoint_cb_info * info = (struct breakpoint_cb_info *)malloc(sizeof(struct breakpoint_cb_info));
    info->callback = (void *)CFBridgingRetain(callback);
    
    NSMapInsert(__breakpoint_cb_infos, &id, info);
    
    _breakpoint.SetCallback(breakpoint_cb_thunk, info);
    
    pthread_rwlock_unlock(&__breakpoint_cb_infos_lock);
}

+ (void)clearAllCallbacks {
    pthread_rwlock_wrlock(&__breakpoint_cb_infos_lock);
    NSResetMapTable(__breakpoint_cb_infos);
    pthread_rwlock_unlock(&__breakpoint_cb_infos_lock);
}

@end
