"break" @keyword
"case" @keyword
"const" @keyword
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
"volatile" @keyword
"while" @keyword

"#define" @keyword
"#elif" @keyword
"#else" @keyword
"#endif" @keyword
"#if" @keyword
"#ifdef" @keyword
"#ifndef" @keyword
"#include" @keyword
(preproc_directive) @keyword

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
  "||"
  "<="
  ">="
  "<<"
  ">>"
  "~"
  "!"
  "."
] @operator

"." @punctuation.delimiter
";" @punctuation.delimiter

(string_literal) @string
(system_lib_string) @string

(null) @value.null
(number_literal) @value.number
(char_literal) @value.number
[
  (true)
  (false)
] @value.boolean

(call_expression
  function: (identifier) @identifier.function)
(call_expression
  function: (field_expression
    field: (field_identifier) @identifier.function))
(function_declarator
  declarator: (identifier) @identifier.function)
(preproc_function_def
  name: (identifier) @identifier.function.special)

(field_identifier) @identifier.property
(statement_identifier) @identifier.label
(type_identifier) @identifier.type
(primitive_type) @identifier.type
(sized_type_specifier) @identifier.type

((identifier) @identifier.constant
 (#match? @identifier.constant "^[A-Z][A-Z\\d_]*$"))

(comment) @comment
