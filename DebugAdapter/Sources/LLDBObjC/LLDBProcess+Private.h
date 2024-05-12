#import "LLDBProcess.h"

@import CLLDB;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBProcess ()

- (instancetype)initWithProcess:(lldb::SBProcess)process NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBProcess process;

@end

@interface LLDBProcessInfo ()

- (instancetype)initWithProcessInfo:(lldb::SBProcessInfo)processInfo NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBProcessInfo processInfo;

@end

NS_ASSUME_NONNULL_END
