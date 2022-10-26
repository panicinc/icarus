#import "LLDBProcess+Private.h"
#import "LLDBThread+Private.h"
#import "LLDBErrors+Private.h"

#import <libproc.h>

@import lldb_API;

@implementation LLDBProcess {
    lldb::SBProcess _process;
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

#define MAX_PROC_NAME_LENGTH 50

- (NSString *)name {
    pid_t pid = (pid_t)_process.GetProcessID();
    char * buffer = (char *)malloc(sizeof(char) * MAX_PROC_NAME_LENGTH);
    int len = proc_name(pid, buffer, MAX_PROC_NAME_LENGTH);
    NSString *string = nil;
    if (len > 0) {
        string = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
    }
    free(buffer);
    return string;
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

- (NSUInteger)threadCount {
    return _process.GetNumThreads();
}

- (LLDBThread *)threadAtIndex:(NSUInteger)idx {
    lldb::SBThread thread = _process.GetThreadAtIndex((size_t)idx);
    if (thread.IsValid()) {
        return [[LLDBThread alloc] initWithThread:thread];
    }
    else {
        return nil;
    }
}

- (LLDBThread *)threadWithID:(uint64_t)threadID {
    lldb::SBThread thread = _process.GetThreadByID(threadID);
    if (thread.IsValid()) {
        return [[LLDBThread alloc] initWithThread:thread];
    }
    else {
        return nil;
    }
}

- (LLDBThread *)threadWithIndexID:(uint32_t)indexID {
    lldb::SBThread thread = _process.GetThreadByIndexID(indexID);
    if (thread.IsValid()) {
        return [[LLDBThread alloc] initWithThread:thread];
    }
    else {
        return nil;
    }
}

- (NSArray<LLDBThread *> *)threads {
    size_t threadCount = _process.GetNumThreads();
    NSMutableArray <LLDBThread *> *threads = [NSMutableArray arrayWithCapacity:threadCount];
    for (size_t i = 0; i < threadCount; i++) {
        lldb::SBThread th = _process.GetThreadAtIndex(i);
        LLDBThread *thread = [[LLDBThread alloc] initWithThread:th];
        [threads addObject:thread];
    }
    return threads;
}

- (LLDBThread *)selectedThread {
    lldb::SBThread thread = _process.GetSelectedThread();
    if (thread.IsValid()) {
        return [[LLDBThread alloc] initWithThread:thread];
    }
    else {
        return nil;
    }
}

- (BOOL)setSelectedThread:(LLDBThread *)thread {
    return _process.SetSelectedThread(thread.thread);
}

- (BOOL)setSelectedThreadByID:(uint64_t)threadID {
    return _process.SetSelectedThreadByID(threadID);
}

- (BOOL)setSelectedThreadByIndexID:(uint32_t)indexID {
    return _process.SetSelectedThreadByIndexID(indexID);
}

- (NSUInteger)writeBytesToStandardIn:(const char *)bytes length:(NSUInteger)length {
    return _process.PutSTDIN(bytes, (size_t)length);
}

- (NSUInteger)writeDataToStandardIn:(NSData *)data {
    return _process.PutSTDIN((const char *)data.bytes, (size_t)data.length);
}

- (NSUInteger)readBytesFromStandardOut:(char *)bytes length:(NSUInteger)length {
    return _process.GetSTDOUT(bytes, (size_t)length);
}

- (NSData *)readDataFromStandardOutToLength:(NSUInteger)length {
    NSMutableData *data = [NSMutableData dataWithLength:length];
    size_t readLength = _process.GetSTDOUT((char *)data.mutableBytes, (size_t)length);
    if (readLength > 0) {
        data.length = readLength;
        return data;
    }
    else {
        return nil;
    }
}

- (NSUInteger)readBytesFromStandardError:(char *)bytes length:(NSUInteger)length {
    return _process.GetSTDERR(bytes, (size_t)length);
}

- (NSData *)readDataFromStandardErrorToLength:(NSUInteger)length {
    NSMutableData *data = [NSMutableData dataWithLength:length];
    size_t readLength = _process.GetSTDERR((char *)data.mutableBytes, (size_t)length);
    data.length = readLength;
    if (readLength > 0) {
        data.length = readLength;
        return data;
    }
    else {
        return nil;
    }
}

- (int)exitStatus {
    return _process.GetExitStatus();
}

- (const char *)exitDescription {
    return _process.GetExitDescription();
}

- (BOOL)resume:(NSError **)outError {
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
