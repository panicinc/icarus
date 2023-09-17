; Types

(namespace_definition
  body: (declaration_list
    "{" @start
    "}" @end))

(class_specifier
  body: (field_declaration_list
  "{" @start
  "}" @end)
  (#set! role type))

; Statements

(try_statement
  body: (compound_statement
    "{" @start
    "}" @end))
(catch_clause
  body: (compound_statement
    "{" @start
    "}" @end))