; Identifiers

(type_identifier) @identifier.type
(primitive_type) @identifier.type.builtin

; Identifier conventions

; Assume all-caps names are constants
((identifier) @identifier.constant
 (#match? @identifier.constant "^[A-Z][A-Z\\d_]+$'"))

; Assume uppercase names are enum constructors
;((identifier) @identifier.function.constructor
; (#match? @identifier.function.constructor "^(?!None$)[A-Z]"))

(tuple_struct_pattern
  type: (identifier) @identifier.function.constructor
  (#match? @identifier.function.constructor "^(?!None$)[A-Z]"))

; Assume that uppercase names in paths are types
((scoped_identifier
  path: (identifier) @identifier.type)
 (#match? @identifier.type "^[A-Z]"))
((scoped_identifier
  path: (scoped_identifier
    name: (identifier) @identifier.type))
 (#match? @identifier.type "^[A-Z]"))
((scoped_type_identifier
  path: (identifier) @identifier.type)
 (#match? @identifier.type "^[A-Z]"))
((scoped_type_identifier
  path: (scoped_identifier
    name: (identifier) @identifier.type))
 (#match? @identifier.type "^[A-Z]"))

; Assume all qualified names in struct patterns are enum constructors. (They're
; either that, or struct names; highlighting both as constructors seems to be
; the less glaring choice of error, visually.)
(struct_pattern
  type: (scoped_type_identifier
    name: (type_identifier) @identifier.function.constructor))

(parameter (identifier) @identifier.argument)

(lifetime (identifier) @identifier.label)

; Fields

((field_expression
  field: (field_identifier) @identifier.property) @_expr
  (#not-has-parent? @_expr "call_expression"))

; Function calls

(call_expression
  function: (identifier) @identifier.function)
(call_expression
  function: (field_expression
    field: (field_identifier) @identifier.method))
(call_expression
  function: (scoped_identifier
    "::"
    name: (identifier) @identifier.function))

(generic_function
  function: (identifier) @identifier.function)
(generic_function
  function: (scoped_identifier
    name: (identifier) @identifier.function))
(generic_function
  function: (field_expression
    field: (field_identifier) @identifier.method))

(macro_invocation
  macro: (identifier) @identifier.function.macro
  "!")

; Function definitions

;(function_item (identifier) @identifier.function)
;(function_signature_item (identifier) @identifier.function)

; Comments

(line_comment) @comment
(block_comment) @comment

(line_comment (doc_comment)) @comment.documentation
(block_comment (doc_comment)) @comment.documentation

; Punctuation

"(" @punctuation.bracket
")" @punctuation.bracket
"[" @punctuation.bracket
"]" @punctuation.bracket
"{" @punctuation.bracket
"}" @punctuation.bracket

(type_arguments
  "<" @punctuation.bracket
  ">" @punctuation.bracket)
(type_parameters
  "<" @punctuation.bracket
  ">" @punctuation.bracket)

"::" @punctuation.delimiter
":" @punctuation.delimiter
"." @punctuation.delimiter
"," @punctuation.delimiter
";" @punctuation.delimiter

; Keywords

[
  "await"
  "break"
  "continue"
  "default"
  "match"
  "move"
  "return"
  "use"
  "yield"
  (crate)
] @keyword

[
  "else"
  "for"
  "if"
  "loop"
  "while"
] @keyword.condition

[
  "const"
  "enum"
  "fn"
  "gen"
  "impl"
  "let"
  "macro_rules!"
  "mod"
  "struct"
  "trait"
  "type"
  "union"
] @keyword.construct

[
  "as"
  "async"
  "dyn"
  "extern"
  "in"
  "pub"
  "raw"
  "ref"
  "static"
  "unsafe"
  "where"
  (mutable_specifier)
] @keyword.modifier

(super) @keyword.self
(self) @keyword.self

; Literals

((identifier) @value.null
  (#eq? @value.null "None"))

(char_literal) @string
(string_literal) @string
(raw_string_literal) @string

(escape_sequence) @string.escape

(boolean_literal) @value.boolean
(integer_literal) @value.number.integer
(float_literal) @value.number.float

(attribute_item) @processing.directive.attribute
(inner_attribute_item) @processing.directive.attribute

; Operators

[
  "="
  "=="
  "!="
  "<="
  ">="
  "+"
  "+="
  "-"
  "-="
  "*"
  "*="
  ;"/" handled below
  "/="
  "%"
  "%="
  "&"
  "&="
  "|"
  "|="
  "^"
  "^="
  "<<"
  "<<="
  ">>"
  ">>="
  ".."
  "..="
  "..."
  "&&"
  "||"
  "=>"
  "->"
  "'"
  "."
  ","
  ";"
  "!"
  "@"
  "?"
  "::"
] @operator

("/" @operator
  (#not-has-parent? @operator "outer_doc_comment_marker"))
