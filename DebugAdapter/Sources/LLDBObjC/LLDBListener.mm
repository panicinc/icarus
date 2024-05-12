#import "LLDBListener+Private.h"
#import "LLDBDebugger+Private.h"
#import "LLDBEvent+Private.h"

@import CLLDB;

@implementation LLDBListener {
    lldb::SBListener _listener;
    NSThread *_thread;
}

- (instancetype)initWithName:(NSString *)name queue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        self.name = name;
        self.queue = queue;
        
        const char * nameStr = name.UTF8String;
        _listener = lldb::SBListener(nameStr);
    }
    return self;
}

- (lldb::SBListener)listener {
    return _listener;
}

- (uint32_t)startListeningInDebugger:(LLDBDebugger *)debugger eventClass:(NSString *)eventClass mask:(uint32_t)eventMask {
    lldb::SBDebugger db = debugger.debugger;
    return _listener.StartListeningForEventClass(db, eventClass.UTF8String, eventMask);
}

- (BOOL)stopListeningInDebugger:(LLDBDebugger *)debugger eventClass:(NSString *)eventClass mask:(uint32_t)eventMask {
    lldb::SBDebugger db = debugger.debugger;
    return _listener.StopListeningForEventClass(db, eventClass.UTF8String, eventMask);
}

- (void)resume {
    @synchronized(self) {
        if (self.listening) {
            return;
        }
        
        self.listening = YES;
        
        __weak LLDBListener *weakSelf = self;
        _thread = [[NSThread alloc] initWithBlock:^{
            LLDBListener *sself = weakSelf;
            if (sself == nil) {
                return;
            }
            
            lldb::SBListener listener = sself->_listener;
            dispatch_queue_t queue = sself.queue;
            
            lldb::SBEvent ev;
            while (sself.listening) {
                if (listener.WaitForEvent(1, ev)) {
                    LLDBEvent *event = [[LLDBEvent alloc] initWithEvent:ev];
                    if (queue != nil) {
                        dispatch_async(queue, ^{
                            void (^eventHandler)(LLDBEvent *) = sself.eventHandler;
                            if (eventHandler != nil) {
                                eventHandler(event);
                            }
                        });
                    }
                    else {
                        void (^eventHandler)(LLDBEvent *) = sself.eventHandler;
                        if (eventHandler != nil) {
                            eventHandler(event);
                        }
                    }
                }
            }
        }];
        _thread.name = @"com.panic.lldbobjc.listener";
        [_thread start];
    }
}

- (void)cancel {
    self.listening = NO;
}

@end
