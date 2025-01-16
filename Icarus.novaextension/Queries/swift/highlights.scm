[ "." ";" ":" "," ] @punctuation.delimiter
[ "\\(" "(" ")" "[" "]" "{" "}" ] @punctuation.bracket

; Keywords
[
  "typealias"
  "struct"
  "class"
  "actor"
  "enum"
  "protocol"
  "extension"
  "associatedtype"
  "package"
  "func"
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
  (try_operator)
  (throws)
  "async"
  "await"
  "return"
  "if"
  (else)
  "subscript"
  "is"
  (as_operator)
  "as"
  "any"
  "some"
  "operator"
  "precedencegroup"
  "each"
  "macro"
] @keyword

[
  (getter_specifier)
  (setter_specifier)
  (modify_specifier)
] @keyword.modifier

[
  "infix"
  "prefix"
  "postfix"
  "indirect"
  "willSet"
  "didSet"
  (where_keyword)
  (visibility_modifier)
  (member_modifier)
  (function_modifier)
  (property_modifier)
  (parameter_modifier)
  (inheritance_modifier)
  (ownership_modifier)
  (mutation_modifier)
  (property_behavior_modifier)
] @keyword.modifier

(metatype [ "Type" "Protocol" ] @keyword)

; Identifiers
(attribute "@" @identifier.decorator.prefix (user_type) @identifier.decorator) ; Target inner nodes to avoid catching arguments
(self_expression) @keyword.self
(inheritance_constraint (identifier (simple_identifier) @identifier.type))
(equality_constraint (identifier (simple_identifier) @identifier.type))
((user_type
    (type_identifier) @identifier.type
  ) @_user_type
  (#not-eq? @identifier.type "self" "Self" "Any" "AnyActor" "AnyClass" "AnyObject" "Type" "Protocol")
  (#not-has-parent? @_user_type "attribute"))
((type_identifier) @identifier.type
  (#not-eq? @identifier.type "self" "Self" "Any" "AnyActor" "AnyClass" "AnyObject" "Type" "Protocol")
  (#not-has-parent? @identifier.type "user_type"))
((type_identifier) @keyword.self
  (#eq? @keyword.self "self" "Self"))
((type_identifier) @keyword
  (#eq? @keyword "Any" "AnyActor" "AnyClass" "AnyObject" "Type" "Protocol"))

; Declarations
(init_declaration "init" @keyword)
(protocol_function_declaration "init" @keyword)
(function_declaration "init" @keyword)
(parameter
  name: (simple_identifier) @identifier.argument)
(deinit_declaration "deinit" @keyword)
(class_declaration
  name: (type_identifier) @identifier.type.declare)
(operator_declaration (simple_identifier) @identifier.type)

; Macros
(macro_declaration
  (simple_identifier) @identifier.type.declare)
(external_macro_definition
  "#externalMacro" @processing.directive)

; Function calls
; foo()
(call_expression (simple_identifier) @identifier.function
  (#not-match? @identifier.function "^[A-Z]")
)
; SomeType()
(call_expression (simple_identifier) @identifier.type
  (#match? @identifier.type "^[A-Z]")
)
; foo.bar.baz(): highlight the baz()
(call_expression
  (navigation_expression
    suffix: (navigation_suffix
      suffix: (simple_identifier) @identifier.method)))
; .baz(): highlight the baz()
(call_expression
  (prefix_expression
    target: (simple_identifier) @identifier.method))
; SomeType.method(): highlight SomeType as a type
((navigation_expression
  (simple_identifier) @identifier.type)
  (#match? @identifier.type "^[A-Z]")
)

; Properties
; foo.bar.baz: highlight the baz
((navigation_expression
  (navigation_suffix
    suffix: (simple_identifier) @identifier.property)) @_nav
  (#not-has-parent? @_nav "call_expression")
)
; .baz: highlight the baz
((prefix_expression
  operation: "."
  target: (simple_identifier) @identifier.property) @_prefix
  (#not-has-parent? @_prefix "call_expression"))

; Arguments
(value_argument name: (value_argument_label) @identifier.argument)

; Directives
(directive) @processing.directive
(diagnostic) @processing.directive

; Statements
(statement_label) @label

; Comments
(comment) @comment
(multiline_comment) @comment

(shebang_line) @processing

; String literals
(line_str_text) @string
(str_escaped_char) @string.escape
(multi_line_str_text) @string
(raw_str_part) @string
(raw_str_end_part) @string
(raw_str_interpolation_start) @bracket
["\"" "\"\"\""] @string.delimiter

; Basic literals
[
 (integer_literal)
 (hex_literal)
 (oct_literal)
 (bin_literal)
 (real_literal)
] @value.number
(boolean_literal) @value.boolean
"nil" @value.null

; Operators
(custom_operator) @operator
[
 "!"
 "?"
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

(ternary_expression ":" @operator)
