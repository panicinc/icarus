#ifdef GET_ATTR_NAMES
#undef GET_ATTR_NAMES
#ifndef ATTRIBUTE_ALL
#define ATTRIBUTE_ALL(FIRST, SECOND)
#endif

#ifndef ATTRIBUTE_ENUM
#define ATTRIBUTE_ENUM(FIRST, SECOND) ATTRIBUTE_ALL(FIRST, SECOND)
#endif

ATTRIBUTE_ENUM(AllocAlign,allocalign)
ATTRIBUTE_ENUM(AllocatedPointer,allocptr)
ATTRIBUTE_ENUM(AlwaysInline,alwaysinline)
ATTRIBUTE_ENUM(Builtin,builtin)
ATTRIBUTE_ENUM(Cold,cold)
ATTRIBUTE_ENUM(Convergent,convergent)
ATTRIBUTE_ENUM(CoroDestroyOnlyWhenComplete,coro_only_destroy_when_complete)
ATTRIBUTE_ENUM(DeadOnUnwind,dead_on_unwind)
ATTRIBUTE_ENUM(DisableSanitizerInstrumentation,disable_sanitizer_instrumentation)
ATTRIBUTE_ENUM(FnRetThunkExtern,fn_ret_thunk_extern)
ATTRIBUTE_ENUM(Hot,hot)
ATTRIBUTE_ENUM(HybridPatchable,hybrid_patchable)
ATTRIBUTE_ENUM(ImmArg,immarg)
ATTRIBUTE_ENUM(InReg,inreg)
ATTRIBUTE_ENUM(InlineHint,inlinehint)
ATTRIBUTE_ENUM(JumpTable,jumptable)
ATTRIBUTE_ENUM(MinSize,minsize)
ATTRIBUTE_ENUM(MustProgress,mustprogress)
ATTRIBUTE_ENUM(Naked,naked)
ATTRIBUTE_ENUM(Nest,nest)
ATTRIBUTE_ENUM(NoAlias,noalias)
ATTRIBUTE_ENUM(NoBuiltin,nobuiltin)
ATTRIBUTE_ENUM(NoCallback,nocallback)
ATTRIBUTE_ENUM(NoCapture,nocapture)
ATTRIBUTE_ENUM(NoCfCheck,nocf_check)
ATTRIBUTE_ENUM(NoDuplicate,noduplicate)
ATTRIBUTE_ENUM(NoFree,nofree)
ATTRIBUTE_ENUM(NoImplicitFloat,noimplicitfloat)
ATTRIBUTE_ENUM(NoInline,noinline)
ATTRIBUTE_ENUM(NoMerge,nomerge)
ATTRIBUTE_ENUM(NoProfile,noprofile)
ATTRIBUTE_ENUM(NoRecurse,norecurse)
ATTRIBUTE_ENUM(NoRedZone,noredzone)
ATTRIBUTE_ENUM(NoReturn,noreturn)
ATTRIBUTE_ENUM(NoSanitizeBounds,nosanitize_bounds)
ATTRIBUTE_ENUM(NoSanitizeCoverage,nosanitize_coverage)
ATTRIBUTE_ENUM(NoSync,nosync)
ATTRIBUTE_ENUM(NoUndef,noundef)
ATTRIBUTE_ENUM(NoUnwind,nounwind)
ATTRIBUTE_ENUM(NonLazyBind,nonlazybind)
ATTRIBUTE_ENUM(NonNull,nonnull)
ATTRIBUTE_ENUM(NullPointerIsValid,null_pointer_is_valid)
ATTRIBUTE_ENUM(OptForFuzzing,optforfuzzing)
ATTRIBUTE_ENUM(OptimizeForDebugging,optdebug)
ATTRIBUTE_ENUM(OptimizeForSize,optsize)
ATTRIBUTE_ENUM(OptimizeNone,optnone)
ATTRIBUTE_ENUM(PresplitCoroutine,presplitcoroutine)
ATTRIBUTE_ENUM(ReadNone,readnone)
ATTRIBUTE_ENUM(ReadOnly,readonly)
ATTRIBUTE_ENUM(Returned,returned)
ATTRIBUTE_ENUM(ReturnsTwice,returns_twice)
ATTRIBUTE_ENUM(SExt,signext)
ATTRIBUTE_ENUM(SafeStack,safestack)
ATTRIBUTE_ENUM(SanitizeAddress,sanitize_address)
ATTRIBUTE_ENUM(SanitizeHWAddress,sanitize_hwaddress)
ATTRIBUTE_ENUM(SanitizeMemTag,sanitize_memtag)
ATTRIBUTE_ENUM(SanitizeMemory,sanitize_memory)
ATTRIBUTE_ENUM(SanitizeNumericalStability,sanitize_numerical_stability)
ATTRIBUTE_ENUM(SanitizeThread,sanitize_thread)
ATTRIBUTE_ENUM(ShadowCallStack,shadowcallstack)
ATTRIBUTE_ENUM(SkipProfile,skipprofile)
ATTRIBUTE_ENUM(Speculatable,speculatable)
ATTRIBUTE_ENUM(SpeculativeLoadHardening,speculative_load_hardening)
ATTRIBUTE_ENUM(StackProtect,ssp)
ATTRIBUTE_ENUM(StackProtectReq,sspreq)
ATTRIBUTE_ENUM(StackProtectStrong,sspstrong)
ATTRIBUTE_ENUM(StrictFP,strictfp)
ATTRIBUTE_ENUM(SwiftAsync,swiftasync)
ATTRIBUTE_ENUM(SwiftError,swifterror)
ATTRIBUTE_ENUM(SwiftSelf,swiftself)
ATTRIBUTE_ENUM(WillReturn,willreturn)
ATTRIBUTE_ENUM(Writable,writable)
ATTRIBUTE_ENUM(WriteOnly,writeonly)
ATTRIBUTE_ENUM(ZExt,zeroext)
ATTRIBUTE_ENUM(ByRef,byref)
ATTRIBUTE_ENUM(ByVal,byval)
ATTRIBUTE_ENUM(ElementType,elementtype)
ATTRIBUTE_ENUM(InAlloca,inalloca)
ATTRIBUTE_ENUM(Preallocated,preallocated)
ATTRIBUTE_ENUM(StructRet,sret)
ATTRIBUTE_ENUM(Alignment,align)
ATTRIBUTE_ENUM(AllocKind,allockind)
ATTRIBUTE_ENUM(AllocSize,allocsize)
ATTRIBUTE_ENUM(Dereferenceable,dereferenceable)
ATTRIBUTE_ENUM(DereferenceableOrNull,dereferenceable_or_null)
ATTRIBUTE_ENUM(Memory,memory)
ATTRIBUTE_ENUM(NoFPClass,nofpclass)
ATTRIBUTE_ENUM(StackAlignment,alignstack)
ATTRIBUTE_ENUM(UWTable,uwtable)
ATTRIBUTE_ENUM(VScaleRange,vscale_range)
ATTRIBUTE_ENUM(Range,range)
ATTRIBUTE_ENUM(Initializes,initializes)
#undef ATTRIBUTE_ENUM

#ifndef ATTRIBUTE_STRBOOL
#define ATTRIBUTE_STRBOOL(FIRST, SECOND) ATTRIBUTE_ALL(FIRST, SECOND)
#endif

ATTRIBUTE_STRBOOL(ApproxFuncFPMath,approx-func-fp-math)
ATTRIBUTE_STRBOOL(LessPreciseFPMAD,less-precise-fpmad)
ATTRIBUTE_STRBOOL(NoInfsFPMath,no-infs-fp-math)
ATTRIBUTE_STRBOOL(NoInlineLineTables,no-inline-line-tables)
ATTRIBUTE_STRBOOL(NoJumpTables,no-jump-tables)
ATTRIBUTE_STRBOOL(NoNansFPMath,no-nans-fp-math)
ATTRIBUTE_STRBOOL(NoSignedZerosFPMath,no-signed-zeros-fp-math)
ATTRIBUTE_STRBOOL(ProfileSampleAccurate,profile-sample-accurate)
ATTRIBUTE_STRBOOL(UnsafeFPMath,unsafe-fp-math)
ATTRIBUTE_STRBOOL(UseSampleProfile,use-sample-profile)
#undef ATTRIBUTE_STRBOOL

#ifndef ATTRIBUTE_COMPLEXSTR
#define ATTRIBUTE_COMPLEXSTR(FIRST, SECOND) ATTRIBUTE_ALL(FIRST, SECOND)
#endif

ATTRIBUTE_COMPLEXSTR(DenormalFPMath,denormal-fp-math)
ATTRIBUTE_COMPLEXSTR(DenormalFPMathF32,denormal-fp-math-f32)
#undef ATTRIBUTE_COMPLEXSTR

#undef ATTRIBUTE_ALL
#endif

#ifdef GET_ATTR_ENUM
#undef GET_ATTR_ENUM
FirstEnumAttr = 1,
AllocAlign = 1,
AllocatedPointer = 2,
AlwaysInline = 3,
Builtin = 4,
Cold = 5,
Convergent = 6,
CoroDestroyOnlyWhenComplete = 7,
DeadOnUnwind = 8,
DisableSanitizerInstrumentation = 9,
FnRetThunkExtern = 10,
Hot = 11,
HybridPatchable = 12,
ImmArg = 13,
InReg = 14,
InlineHint = 15,
JumpTable = 16,
MinSize = 17,
MustProgress = 18,
Naked = 19,
Nest = 20,
NoAlias = 21,
NoBuiltin = 22,
NoCallback = 23,
NoCapture = 24,
NoCfCheck = 25,
NoDuplicate = 26,
NoFree = 27,
NoImplicitFloat = 28,
NoInline = 29,
NoMerge = 30,
NoProfile = 31,
NoRecurse = 32,
NoRedZone = 33,
NoReturn = 34,
NoSanitizeBounds = 35,
NoSanitizeCoverage = 36,
NoSync = 37,
NoUndef = 38,
NoUnwind = 39,
NonLazyBind = 40,
NonNull = 41,
NullPointerIsValid = 42,
OptForFuzzing = 43,
OptimizeForDebugging = 44,
OptimizeForSize = 45,
OptimizeNone = 46,
PresplitCoroutine = 47,
ReadNone = 48,
ReadOnly = 49,
Returned = 50,
ReturnsTwice = 51,
SExt = 52,
SafeStack = 53,
SanitizeAddress = 54,
SanitizeHWAddress = 55,
SanitizeMemTag = 56,
SanitizeMemory = 57,
SanitizeNumericalStability = 58,
SanitizeThread = 59,
ShadowCallStack = 60,
SkipProfile = 61,
Speculatable = 62,
SpeculativeLoadHardening = 63,
StackProtect = 64,
StackProtectReq = 65,
StackProtectStrong = 66,
StrictFP = 67,
SwiftAsync = 68,
SwiftError = 69,
SwiftSelf = 70,
WillReturn = 71,
Writable = 72,
WriteOnly = 73,
ZExt = 74,
LastEnumAttr = 74,
FirstTypeAttr = 75,
ByRef = 75,
ByVal = 76,
ElementType = 77,
InAlloca = 78,
Preallocated = 79,
StructRet = 80,
LastTypeAttr = 80,
FirstIntAttr = 81,
Alignment = 81,
AllocKind = 82,
AllocSize = 83,
Dereferenceable = 84,
DereferenceableOrNull = 85,
Memory = 86,
NoFPClass = 87,
StackAlignment = 88,
UWTable = 89,
VScaleRange = 90,
LastIntAttr = 90,
FirstConstantRangeAttr = 91,
Range = 91,
LastConstantRangeAttr = 91,
FirstConstantRangeListAttr = 92,
Initializes = 92,
LastConstantRangeListAttr = 92,
#endif

#ifdef GET_ATTR_COMPAT_FUNC
#undef GET_ATTR_COMPAT_FUNC
static inline bool hasCompatibleFnAttrs(const Function &Caller,
                                        const Function &Callee) {
  bool Ret = true;

  Ret &= isEqual<SanitizeAddressAttr>(Caller, Callee);
  Ret &= isEqual<SanitizeThreadAttr>(Caller, Callee);
  Ret &= isEqual<SanitizeMemoryAttr>(Caller, Callee);
  Ret &= isEqual<SanitizeHWAddressAttr>(Caller, Callee);
  Ret &= isEqual<SanitizeMemTagAttr>(Caller, Callee);
  Ret &= isEqual<SanitizeNumericalStabilityAttr>(Caller, Callee);
  Ret &= isEqual<SafeStackAttr>(Caller, Callee);
  Ret &= isEqual<ShadowCallStackAttr>(Caller, Callee);
  Ret &= isEqual<UseSampleProfileAttr>(Caller, Callee);
  Ret &= isEqual<NoProfileAttr>(Caller, Callee);
  Ret &= checkDenormMode(Caller, Callee);
  Ret &= checkStrictFP(Caller, Callee);
  Ret &= isEqual(Caller, Callee, "sign-return-address");
  Ret &= isEqual(Caller, Callee, "sign-return-address-key");
  Ret &= isEqual(Caller, Callee, "branch-protection-pauth-lr");

  return Ret;
}

static inline void mergeFnAttrs(Function &Caller,
                                const Function &Callee) {
  setAND<LessPreciseFPMADAttr>(Caller, Callee);
  setAND<NoInfsFPMathAttr>(Caller, Callee);
  setAND<NoNansFPMathAttr>(Caller, Callee);
  setAND<ApproxFuncFPMathAttr>(Caller, Callee);
  setAND<NoSignedZerosFPMathAttr>(Caller, Callee);
  setAND<UnsafeFPMathAttr>(Caller, Callee);
  setOR<NoImplicitFloatAttr>(Caller, Callee);
  setOR<NoJumpTablesAttr>(Caller, Callee);
  setOR<ProfileSampleAccurateAttr>(Caller, Callee);
  setOR<SpeculativeLoadHardeningAttr>(Caller, Callee);
  adjustCallerSSPLevel(Caller, Callee);
  adjustCallerStackProbes(Caller, Callee);
  adjustCallerStackProbeSize(Caller, Callee);
  adjustMinLegalVectorWidth(Caller, Callee);
  adjustNullPointerValidAttr(Caller, Callee);
  setAND<MustProgressAttr>(Caller, Callee);
}

#endif
#ifdef GET_ATTR_PROP_TABLE
#undef GET_ATTR_PROP_TABLE
static const uint8_t AttrPropTable[] = {
0 | AttributeProperty::ParamAttr,
0 | AttributeProperty::ParamAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::ParamAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::ParamAttr,
0 | AttributeProperty::ParamAttr | AttributeProperty::RetAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::ParamAttr,
0 | AttributeProperty::ParamAttr | AttributeProperty::RetAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::ParamAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr | AttributeProperty::ParamAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::ParamAttr | AttributeProperty::RetAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::ParamAttr | AttributeProperty::RetAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::ParamAttr,
0 | AttributeProperty::ParamAttr,
0 | AttributeProperty::ParamAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::ParamAttr | AttributeProperty::RetAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::ParamAttr,
0 | AttributeProperty::ParamAttr,
0 | AttributeProperty::ParamAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::ParamAttr,
0 | AttributeProperty::ParamAttr,
0 | AttributeProperty::ParamAttr | AttributeProperty::RetAttr,
0 | AttributeProperty::ParamAttr,
0 | AttributeProperty::ParamAttr,
0 | AttributeProperty::ParamAttr,
0 | AttributeProperty::ParamAttr,
0 | AttributeProperty::FnAttr | AttributeProperty::ParamAttr,
0 | AttributeProperty::ParamAttr,
0 | AttributeProperty::ParamAttr | AttributeProperty::RetAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::ParamAttr | AttributeProperty::RetAttr,
0 | AttributeProperty::ParamAttr | AttributeProperty::RetAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::ParamAttr | AttributeProperty::RetAttr,
0 | AttributeProperty::FnAttr | AttributeProperty::ParamAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::FnAttr,
0 | AttributeProperty::ParamAttr | AttributeProperty::RetAttr,
0 | AttributeProperty::ParamAttr,
};
#endif
