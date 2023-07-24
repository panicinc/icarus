#import "LLDBFileSpec+Private.h"

@implementation LLDBFileSpec {
    lldb::SBFileSpec _fileSpec;
}

- (instancetype)initWithFileSpec:(lldb::SBFileSpec)fileSpec {
    self = [super init];
    if (self) {
        _fileSpec = fileSpec;
    }
    return self;
}

- (lldb::SBFileSpec)fileSpec {
    return _fileSpec;
}

- (NSString *)directory {
    const char *directory = _fileSpec.GetDirectory();
    return (directory != NULL ? @(directory) : NULL);
}

- (NSString *)filename {
    const char *filename = _fileSpec.GetFilename();
    return (filename != NULL ? @(filename) : NULL);
}

- (NSString *)fullpath {
    const char * directory = _fileSpec.GetDirectory();
    const char * filename = _fileSpec.GetFilename();
    if (directory != NULL && filename != NULL) {
        return [[NSURL fileURLWithPath:@(directory) isDirectory:YES] URLByAppendingPathComponent:@(filename) isDirectory:NO].path;
    }
    else {
        return nil;
    }
}

@end
