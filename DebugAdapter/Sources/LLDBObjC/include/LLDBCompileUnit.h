@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class LLDBFileSpec, LLDBLineEntry;

@interface LLDBCompileUnit : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly) LLDBFileSpec *fileSpec;

@property (readonly) NSUInteger lineEntryCount;
- (nullable LLDBLineEntry *)lineEntryAtIndex:(NSUInteger)idx;
@property (copy, readonly) NSArray <LLDBLineEntry *> *lineEntries;

@end

NS_ASSUME_NONNULL_END
