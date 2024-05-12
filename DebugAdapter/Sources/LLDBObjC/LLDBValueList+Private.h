#import "LLDBValueList.h"

@import CLLDB;

NS_ASSUME_NONNULL_BEGIN

@interface LLDBValueList ()

- (instancetype)initWithValueList:(lldb::SBValueList)valueList NS_DESIGNATED_INITIALIZER;

@property (readonly) lldb::SBValueList valueList;

@end

NS_ASSUME_NONNULL_END
