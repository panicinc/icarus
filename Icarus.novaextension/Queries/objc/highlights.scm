[ "." ";" ":" "," ] @punctuation.delimiter
[ "(" ")" "[" "]" "{" "}" ] @punctuation.bracket

[
  (comment)
] @comment

((pragma) @comment
  (#match? @comment "^#pragma\\s+mark\\s+"))
((pragma) @processing.directive
  (#not-match? @processing.directive "^#pragma\\s+mark\\s+"))

[
  (self)
  (super)
] @keyword.self

[
  (getter)
  (setter)
  (nonnull)
  (nullable)
  (null_resettable)
  (unsafe_unretained)
  (null_unspecified)
  (direct)
  (readwrite)
  (readonly)
  (strong)
  (weak)
  (copy)
  (assign)
  (retain)
  (atomic)
  (nonatomic)
  (class)
  (NS_NONATOMIC_IOSONLY)
  (DISPATCH_QUEUE_REFERENCE_TYPE)
] @keyword.modifier

[
  "@interface"
  "@protocol"
  "@property"
  "@end"
  "@implementation"
  "@compatibility_alias"
  "@autoreleasepool"
  "@synchronized"
  "@class"
  "@synthesize"
  "@dynamic"
  "@defs"
  "@try"
  "@catch"
  "@finally"
  "@throw"
  "@selector"
  "@encode"
  "NS_ENUM"
  "NS_ERROR_ENUM"
  "NS_OPTIONS"
  "NS_SWIFT_NAME"
  "enum"
  "struct"
  "union"
  "goto"
  "typedef"
  "typeof"
  "__typeof"
  "__typeof__"
  "default"
] @keyword

[
  (private)
  (public)
  (protected)
  (package)
  (optional)
  (required)
  (type_qualifier)
  (storage_class_specifier)
  "NS_NOESCAPE"
  "const"
  "extern"
  "inline"
  "static"
  "_Atomic"
  "volatile"
  "register"
  "__covariant"
  "__contravariant"
  "__GENERICS"
] @keyword.modifier

"sizeof" @keyword.operator
"return" @keyword.return

[
  "while"
  "for"
  "do"
  "continue"
  "break"
  "in"
] @keyword.repeat

"#define" @identifier.constant.macro

"#include" @declaration.include
"#import" @declaration.include
"@import" @declaration.include

[
  "="

  "-"
  "*"
  "/"
  "+"
  "%"

  "~"
  "|"
  "&"
  "^"
  "<<"
  ">>"

  "->"

  "<"
  "<="
  ">="
  ">"
  "=="
  "!="

  "!"
  "&&"
  "||"

  "-="
  "+="
  "*="
  "/="
  "%="
  "|="
  "&="
  "^="
  ">>="
  "<<="
  "--"
  "++"
] @operator

[
 "if"
 "else"
 "case"
 "switch"
] @keyword.conditional

(conditional_expression [ "?" ":" ] @keyword.conditional)

[
 (true)
 (false)
 (YES)
 (NO)
] @keyword.boolean

[ "." ";" ":" "," ] @punctuation.delimiter

"..." @punctuation.special

[ "(" ")" "[" "]" "{" "}"] @punctuation.bracket

[
  (string_literal)
  (string_expression)
  (system_lib_string)
  (module_string)
] @string

(escape_sequence) @value.number

(null) @value.null
(nil) @value.null
(number_literal) @value.number
(char_literal) @value.number
(number_expression
  "@" @value.number.prefix) @value.number
(boolean_expression
  "@" @value.boolean.prefix) @value.boolean
(object_expression
  "@" @value.number.prefix
  "(" @value.number
  ")" @value.number)
(array_expression
  "@" @value.number.prefix
  "[" @value.number
  "]" @value.number)
(dictionary_expression
  "@" @value.number.prefix
  "{" @value.number
  "}" @value.number)

((type_identifier) @identifier.type
  (#match? @identifier.type "^[A-Z]"))

[
 (sized_type_specifier)
 (type_descriptor)
 (generics_type_reference)
] @identifier.type

[
 (primitive_type)
 (id)
 (Class)
 (Method)
 (IMP)
 (SEL)
 (BOOL)
 (instancetype)
 (auto)
] @keyword.type

(cast_expression type: (type_descriptor) @identifier.type)
(sizeof_expression value: (parenthesized_expression (identifier) @identifier.type))

;; Type Class & Category & Protocol
(class_interface name: (identifier) @identifier.type.class.declare)
(category_interface name: (identifier) @identifier.type.class.declare)
(category_interface category: (identifier) @identifier.type.category)
(superclass_reference name: (identifier) @identifier.type.class)
(parameterized_class_type_arguments) @identifier.type.class
(class_implementation name: (identifier) @identifier.type.class.declare)
(category_implementation name: (identifier) @identifier.type.class.declare)
(compatibility_alias_declaration (identifier) @identifier.type.class)
(parameterized_class_type_arguments (identifier) @identifier.type.class)
(category_implementation category: (identifier) @identifier.type.category)
(class_forward_declaration name: (identifier) @identifier.type.class)
(protocol_forward_declaration name: (identifier) @identifier.type.protocol)
(protocol_declaration name: (identifier) @identifier.type.protocol.declare)
(protocol_qualifiers name: (identifier) @identifier.type.protocol
  (#not-match? @identifier.type.protocol "^id$"))
(protocol_qualifiers name: (identifier) @keyword.type
  (#match? @keyword.type "^id$"))
(protocol_expression (identifier) @identifier.type.protocol)

(ns_enum_specifier name: (type_identifier) @identifier.type.enum.declare)

;; Property
; (property_declaration
  ; type: _ @identifier.type
  ; declarator: (identifier) @identifier.property)

; (property_declaration
  ; type: _ @identifier.type
  ; declarator: (_
  ;   declarator: (identifier) @identifier.property))

; (property_declaration
  ; type: _ @identifier.type
  ; declarator: (_
  ;   declarator: (_
  ;     declarator: (identifier) @identifier.property)))

(((field_expression
 (field_identifier) @identifier.property)) @_parent
 (#not-has-parent? @_parent function_declarator call_expression))

(field_expression
  field: (field_identifier) @identifier.property)

; (((field_identifier) @identifier.property)
;  (#has-ancestor? @identifier.property field_declaration)
;  (#not-has-ancestor? @identifier.property function_declarator))

;; Variable
; declarator: (identifier) @identifier.variable

; (cast_expression value: (identifier) @identifier.variable)

;; Function
(call_expression
  function: (identifier) @identifier.function)
(function_declarator
  declarator: (identifier) @identifier.function)
(selector_expression
  name: (identifier) @identifier.function)
; (method_declaration
;   selector: (identifier) @identifier.function)

; (method_declaration
;   (keyword_selector
;     (keyword_declarator
;       keyword: (identifier) @identifier.function)))

; (method_declaration
;   (keyword_selector
;     (keyword_declarator
;       name: (identifier) @identifier.variable.parameter)))

; (message_expression
;   receiver: (field_expression
;     field: (field_identifier) @identifier.function))

; (method_definition
;   selector: (identifier) @identifier.function)

(swift_name_attribute_sepcifier
  method: (identifier) @identifier.function)

(setter
  name: (identifier) @identifier.function)

; (method_definition
;   (keyword_selector
;     (keyword_declarator
;       keyword: (identifier) @identifier.function)))

(message_expression
  selector: (identifier) @identifier.function)

; (method_definition
;   (keyword_selector
;     (keyword_declarator
;       name: (identifier) @identifier.variable.parameter)))

(message_expression
  selector: (keyword_argument_list
    (keyword_argument
      keyword: (identifier) @identifier.function)))

; (message_expression
;   selector: (keyword_argument_list
;     (keyword_argument
;       argument: (identifier) @identifier.variable.parameter)))

(unary_expression argument: (identifier) @identifier.function)
(va_arg_expression) @identifier.function
(va_arg_expression va_list: (identifier) @identifier.variable)


;; Parameters
; (parameter_declaration
;   declarator: (identifier) @identifier.variable.parameter)
;
; (parameter_declaration
;   declarator: (pointer_declarator) @identifier.variable.parameter)
;
; (parameter_declaration
;   declarator: (pointer_declarator
;     declarator: (identifier) @identifier.variable.parameter))

; (for_in_statement
;   loop: (identifier) @identifier.variable)
;
; (dictionary_expression
;   key: (_expression) @identifier.variable)
; (dictionary_expression
;   value: (_expression) @identifier.variable)
; (array_expression
;   (identifier) @identifier.variable)
; (argument_list
;   (identifier) @identifier.variable)
; (expression_statement
;   (identifier) @identifier.variable)
; (_expression (identifier) @identifier.variable)

[
  "__attribute"
  "__attribute__"
  "__cdecl"
  "__clrcall"
  "__stdcall"
  "__fastcall"
  "__thiscall"
  "__vectorcall"
  "_unaligned"
  "__unaligned"
  "__declspec"
  "__unused"
  "__builtin_available"
  "@available"
  (attribute_specifier)
  (class_interface_attribute_sepcifier)
  (method_variadic_arguments_attribute_specifier)
] @keyword.modifier.attribute

(attribute_specifier) @keyword.modifier.attribute

(ERROR) @error