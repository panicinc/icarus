; Preprocs

(preproc_undef
  name: (_) @identifier.constant) @processing.directive

; Includes

(module_import "@import" @keyword.include path: (identifier) @identifier.namespace)

((preproc_include
  _ @processing.directive path: (_))
  (#eq? @processing.directive "#include" "#import"))

; Type Qualifiers

[
  "@optional"
  "@required"
  "__covariant"
  "__contravariant"
  (visibility_specification)
] @keyword.modifier

; Storageclasses

[
  "@autoreleasepool"
  "@synthesize"
  "@dynamic"
  "volatile"
  (protocol_qualifier)
] @keyword.modifier

; Keywords

[
  "@protocol"
  "@interface"
  "@implementation"
  "@compatibility_alias"
  "@property"
  "@selector"
  "@defs"
  "availability"
  "@end"
] @keyword

(class_declaration "@" @keyword "class" @keyword) ; I hate Obj-C for allowing "@ class" :)

[
  "__typeof__"
  "__typeof"
  "typeof"
  "in"
] @keyword.modifier

[
  "@synchronized"
  "oneway"
] @keyword.modifier

; Exceptions

[
  "@try"
  "__try"
  "@catch"
  "__catch"
  "@finally"
  "__finally"
  "@throw"
  "@available"
] @keyword

; Variables

((identifier) @keyword
  (#eq? @keyword "self" "super"))

(method_identifier (identifier)? @identifier.method ":" @identifier.method (identifier)? @identifier.method)

(message_expression method: (identifier) @identifier.method)

(field_expression field: (field_identifier) @identifier.property)

; Constructors

((message_expression method: (identifier) @identifier.constructor)
  (#eq? @identifier.constructor "init"))

; Attributes

(availability_attribute_specifier 
  [
    "CF_FORMAT_FUNCTION" "NS_AVAILABLE" "__IOS_AVAILABLE" "NS_AVAILABLE_IOS"
    "API_AVAILABLE" "API_UNAVAILABLE" "API_DEPRECATED" "NS_ENUM_AVAILABLE_IOS"
    "NS_DEPRECATED_IOS" "NS_ENUM_DEPRECATED_IOS" "NS_FORMAT_FUNCTION" "DEPRECATED_MSG_ATTRIBUTE"
    "__deprecated_msg" "__deprecated_enum_msg" "NS_SWIFT_NAME" "NS_SWIFT_UNAVAILABLE"
    "NS_EXTENSION_UNAVAILABLE_IOS" "NS_CLASS_AVAILABLE_IOS" "NS_CLASS_DEPRECATED_IOS" "__OSX_AVAILABLE_STARTING"
    "NS_ROOT_CLASS" "NS_UNAVAILABLE" "NS_REQUIRES_NIL_TERMINATION" "CF_RETURNS_RETAINED"
    "CF_RETURNS_NOT_RETAINED" "DEPRECATED_ATTRIBUTE" "UI_APPEARANCE_SELECTOR" "UNAVAILABLE_ATTRIBUTE"
  ]) @processing.directive

; Macros

(type_qualifier
  [
    "nullable"
    "_Complex"
    "_Nonnull"
    "_Nullable"
    "_Nullable_result"
    "_Null_unspecified"
    "__autoreleasing"
    "__block"
    "__bridge"
    "__bridge_retained"
    "__bridge_transfer"
    "__complex"
    "__kindof"
    "__nonnull"
    "__nullable"
    "__ptrauth_objc_class_ro"
    "__ptrauth_objc_isa_pointer"
    "__ptrauth_objc_super_pointer"
    "__strong"
    "__thread"
    "__unsafe_unretained"
    "__unused"
    "__weak"
  ]) @keyword.modifier

; Types

(class_declaration (identifier) @identifier.type)

(class_interface "@interface" . (identifier) @identifier.type.declare superclass: _? @identifier.type category: _? @identifier.type)

(class_implementation "@implementation" . (identifier) @identifier.type.declare superclass: _? @identifier.type category: _? @identifier.type)

(protocol_declaration "@protocol" . (identifier) @identifier.type.declare)

(protocol_forward_declaration (identifier) @identifier.type) ; @interface :(

(protocol_reference_list (identifier) @identifier.type) ; ^

[
  "BOOL"
  "IMP"
  "SEL"
  "Class"
  "id"
] @identifier.type

((identifier) @value.null
  (#eq? @value.null "nil" "Nil"))

((identifier) @value.boolean
  (#eq? @value.boolean "YES" "NO"))

; Constants

(property_attribute (identifier) @keyword.modifier "="?)

; Parameters

(parameter_declaration 
  declarator: (function_declarator 
                declarator: (parenthesized_declarator 
                              (block_pointer_declarator 
                                declarator: (identifier) @identifier.argument))))

"..." @operator

; Operators

[
  "^"
] @operator

; Literals

(at_expression "@" @keyword)
(array_literal "@" @keyword)
(dictionary_literal "@" @keyword)

(platform) @string

(version_number) @value.number

; Punctuation

[ "<" ">" ] @punctuation.bracket
