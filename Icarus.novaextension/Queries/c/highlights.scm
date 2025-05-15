[ "." ";" ":" "," ] @punctuation.delimiter
[ "(" ")" "[" "]" "{" "}" ] @punctuation.bracket

; Keywords
"break" @keyword
"case" @keyword
"continue" @keyword
"default" @keyword
"do" @keyword
"else" @keyword
"enum" @keyword
"extern" @keyword
"for" @keyword
"if" @keyword
"inline" @keyword
"return" @keyword
"sizeof" @keyword
"static" @keyword
"struct" @keyword
"switch" @keyword
"typedef" @keyword
"union" @keyword
"while" @keyword
"goto" @keyword

[
  (type_qualifier) ; Covers "const", "constexpr", "restrict", "_Noreturn", etc.
  (storage_class_specifier)
  (ms_based_modifier) 
  (ms_call_modifier)
  (ms_declspec_modifier)
  (ms_pointer_modifier)
] @keyword.modifier

; Operators
[
  "--"
  "-"
  "-="
  "->"
  "="
  "!="
  "*"
  "&"
  "&&"
  "+"
  "++"
  "+="
  "<"
  "=="
  ">"
  "|"
  "||"
  "<="
  ">="
  "<<"
  ">>"
  "~"
  "!"
  "."
  ":"
  "^"
] @operator

(conditional_expression "?" @operator ":" @operator)

"." @punctuation.delimiter
";" @punctuation.delimiter

; Literals
(string_literal
  . "\"" @string.delimiter.left
  "\"" @string.delimiter.right .) @string
(string_literal
  (escape_sequence) @string.escape)
(system_lib_string) @string

(null) @value.null
(number_literal) @value.number
(char_literal) @value.number
[
  (true)
  (false)
] @value.boolean

; Identifiers
(call_expression
  function: (identifier) @identifier.function)
(call_expression
  function: (field_expression
    field: (field_identifier) @identifier.function))

(statement_identifier) @identifier.label
(type_identifier) @identifier.type
(primitive_type) @identifier.type
(sized_type_specifier) @identifier.type

; Declarations

(struct_specifier name: (type_identifier) @identifier.type.declare)
(union_specifier name: (type_identifier) @identifier.type.declare)
(enum_specifier name: (type_identifier) @identifier.type.declare)
(type_definition declarator: (type_identifier) @identifier.type.declare)
(function_declarator declarator: (identifier) @identifier.function.declare)

; Expressions
(field_expression
  field: (field_identifier) @identifier.property)

; Comments
(comment) @comment
