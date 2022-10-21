#import "LLDBProcess+Private.h"
#import "LLDBBroadcaster+Private.h"
#import "LLDBErrors+Private.h"

@import lldb_API;

@implementation LLDBProcess {
    lldb::SBProcess _process;
    LLDBBroadcaster *_broadcaster;
}

+ (NSString *)broadcasterClassName {
    return @(lldb::SBProcess::GetBroadcasterClassName());
}

- (instancetype)initWithProcess:(lldb::SBProcess)process {
    self = [super init];
    if (self) {
        _process = process;
    }
    return self;
}

- (lldb::SBProcess)process {
    return _process;
}

- (LLDBProcessState)state {
    lldb::StateType state = _process.GetState();
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

- (pid_t)processIdentifier {
    return (pid_t)_process.GetProcessID();
}

- (uint32_t)uniqueIdentifier {
    return _process.GetUniqueID();
}

- (CFByteOrder)byteOrder {
    lldb::ByteOrder byteOrder = _process.GetByteOrder();
    switch (byteOrder) {
    case lldb::eByteOrderBig:
        return CFByteOrderBigEndian;
    case lldb::eByteOrderLittle:
        return CFByteOrderLittleEndian;
    case lldb::eByteOrderInvalid:
    case lldb::eByteOrderPDP:
        return CFByteOrderUnknown;
    }
}

- (uint32_t)addressByteSize {
    return _process.GetAddressByteSize();
}

- (LLDBBroadcaster *)broadcaster {
    @synchronized(self) {
        if (_broadcaster == nil) {
            lldb::SBBroadcaster bc = _process.GetBroadcaster();
            _broadcaster = [[LLDBBroadcaster alloc] initWithBroadcaster:bc];
        }
        return _broadcaster;
    }
}

- (int)exitStatus {
    return _process.GetExitStatus();
}

- (const char *)exitDescription {
    return _process.GetExitDescription();
}

- (BOOL)continue:(NSError **)outError {
    lldb::SBError error = _process.Continue();
    if (error.Success()) {
        return YES;
    }
    else {
        if (outError != NULL) {
            *outError = [NSError lldb_errorWithLLDBError:error];
        }
        return NO;
    }
}

- (BOOL)stop:(NSError *__autoreleasing *)outError {
    lldb::SBError error = _process.Stop();
    if (error.Success()) {
        return YES;
    }
    else {
        if (outError != NULL) {
            *outError = [NSError lldb_errorWithLLDBError:error];
        }
        return NO;
    }
}

- (BOOL)kill:(NSError *__autoreleasing *)outError {
    lldb::SBError error = _process.Kill();
    if (error.Success()) {
        return YES;
    }
    else {
        if (outError != NULL) {
            *outError = [NSError lldb_errorWithLLDBError:error];
        }
        return NO;
    }
}

- (BOOL)detach:(NSError *__autoreleasing *)outError {
    lldb::SBError error = _process.Detach();
    if (error.Success()) {
        return YES;
    }
    else {
        if (outError != NULL) {
            *outError = [NSError lldb_errorWithLLDBError:error];
        }
        return NO;
    }
}

- (BOOL)signal:(int)signal error:(NSError *__autoreleasing *)outError {
    lldb::SBError error = _process.Signal(signal);
    if (error.Success()) {
        return YES;
    }
    else {
        if (outError != NULL) {
            *outError = [NSError lldb_errorWithLLDBError:error];
        }
        return NO;
    }
}

- (NSData *)readMemoryAtAddress:(uint64_t)address size:(size_t)size error:(NSError *__autoreleasing *)outError {
    NSMutableData *data = [NSMutableData dataWithCapacity:size];
    lldb::SBError error;
    size_t writtenSize = _process.ReadMemory(address, data.mutableBytes, size, error);
    if (writtenSize > 0.0) {
        data.length = writtenSize;
        return data;
    }
    else {
        if (outError != NULL) {
            *outError = [NSError lldb_errorWithLLDBError:error];
        }
        return nil;
    }
}

- (size_t)writeMemoryAtAddress:(uint64_t)address data:(NSData *)data error:(NSError *__autoreleasing *)outError {
    lldb::SBError error;
    return _process.WriteMemory(address, data.bytes, (size_t)data.length, error);
}

@end
