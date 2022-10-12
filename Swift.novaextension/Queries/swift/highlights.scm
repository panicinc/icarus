[ "." ";" ":" "," ] @punctuation.delimiter
[ "\\(" "(" ")" "[" "]" "{" "}" ] @punctuation.bracket

; Identifiers
(type_identifier) @identifier.type
(attribute "@" @keyword (user_type) @keyword)
(self_expression) @keyword.self

; Declarations
(function_declaration (simple_identifier) @identifier.function)
(function_declaration ["init" @identifier.function.constructor])

(parameter name: (simple_identifier) @identifier.argument)
(type_parameter (type_identifier) @identifier.argument)
(inheritance_constraint (identifier (simple_identifier) @identifier.argument))
(equality_constraint (identifier (simple_identifier) @identifier.argument))

[
  "typealias"
  "struct"
  "class"
  "enum"
  "protocol"
  "extension"
  "indirect"
  "func"
  "some"
  "case"
  "import"
  "for"
  "in"
  "while"
  "repeat"
  "continue"
  "break"
  "let"
  "var"
  "guard"
  "switch"
  "fallthrough"
  (default_keyword)
  "do"
  (throw_keyword)
  (catch_keyword)
  "try"
  "try?"
  "try!"
  (throws) @keyword
  "async" @keyword
  (where_keyword) @keyword
  "return"
  (else)
  (as_operator)
] @keyword

[
  (getter_specifier)
  (setter_specifier)
  (modify_specifier)
] @keyword.modifier
[
  (visibility_modifier)
  (member_modifier)
  (function_modifier)
  (property_modifier)
  (parameter_modifier)
  (inheritance_modifier)
  (ownership_modifier)
] @keyword.modifier

(class_body (property_declaration (pattern (simple_identifier) @identifier.property)))
(protocol_property_declaration (pattern (simple_identifier) @identifier.property))

; Function calls
(call_expression (simple_identifier) @identifier.function) ; foo()
(call_expression ; foo.bar.baz(): highlight the baz()
  (navigation_expression
    (navigation_suffix (simple_identifier) @identifier.method)))
(call_expression ; .baz(): highlight the baz()
  (prefix_expression
    target: (simple_identifier) @identifier.method))
((navigation_expression
  (simple_identifier) @identifier.type) ; SomeType.method(): highlight SomeType as a type
  (#match? @identifier.type "^[A-Z]"))
((navigation_expression
  (navigation_suffix
      suffix: (simple_identifier) @identifier.property)))
(value_argument name: (simple_identifier) @identifier.function)
(value_argument value: (prefix_expression (simple_identifier) @identifier.property))

(directive) @identifier.function.macro
(diagnostic) @identifier.function.macro

; Statements
(for_statement item: (simple_identifier) @identifier.variable)

(statement_label) @label

; Comments
(comment) @comment
(multiline_comment) @comment

; String literals
(line_str_text) @string
(str_escaped_char) @string
(multi_line_str_text) @string
(raw_str_part) @string
(raw_str_end_part) @string
(raw_str_interpolation_start) @punctuation.special
["\"" "\"\"\""] @string

; Basic literals
[
 (integer_literal)
 (hex_literal)
 (oct_literal)
 (bin_literal)
] @value.number
(real_literal) @value.number
(boolean_literal) @value.boolean
"nil" @value.null

; Operators
(custom_operator) @operator
[
 "!"
 "+"
 "-"
 "*"
 "/"
 "%"
 "="
 "+="
 "-="
 "*="
 "/="
 "<"
 ">"
 "<="
 ">="
 "++"
 "--"
 "&"
 "~"
 "%="
 "!="
 "!=="
 "=="
 "==="
 "??"
 "&&"
 "||"

 "->"

 "..<"
 "..."
] @operator

(optional_type "?") @operator

(ternary_expression ["?" ":"] @operator)
