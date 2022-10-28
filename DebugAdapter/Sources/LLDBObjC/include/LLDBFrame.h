@import Foundation;

NS_ASSUME_NONNULL_BEGIN

// Equivalent to lldb:SymbolContextItem
typedef NS_OPTIONS(uint32_t, LLDBSymbolContextItem) {
    LLDBSymbolContextItemTarget = (1u << 0),
    LLDBSymbolContextItemModule = (1u << 1),
    LLDBSymbolContextItemCompUnit = (1u << 2),
    LLDBSymbolContextItemFunction = (1u << 3),
    LLDBSymbolContextItemBlock = (1u << 4),
    LLDBSymbolContextItemLineEntry = (1u << 5),
    LLDBSymbolContextItemSymbol = (1u << 6),
    LLDBSymbolContextItemEverything = ((LLDBSymbolContextItemSymbol << 1) - 1u),
    LLDBSymbolContextItemVariable = (1u << 7),
};

@class LLDBCompileUnit, LLDBLineEntry, LLDBSymbolContext, LLDBValueList;

@interface LLDBFrame : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (readonly) uint32_t frameID;

@property (readonly) LLDBLineEntry *lineEntry;

- (LLDBSymbolContext *)symbolContextWithItems:(LLDBSymbolContextItem)items;

@property (nullable, copy, readonly) NSString *functionName;
@property (nullable, copy, readonly) NSString *displayFunctionName;

@property (readonly) uint64_t pcAddress;

@property (readonly, getter=isInlined) BOOL inlined;
@property (readonly, getter=isArtificial) BOOL artificial;

@property (readonly) LLDBCompileUnit *compileUnit;

@property (readonly) LLDBValueList *registers;

- (LLDBValueList *)variablesWithArguments:(BOOL)arguments locals:(BOOL)locals statics:(BOOL)statics inScopeOnly:(BOOL)inScopeOnly;

@end

NS_ASSUME_NONNULL_END
