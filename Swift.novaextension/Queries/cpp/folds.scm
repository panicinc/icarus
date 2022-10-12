(namespace_definition
  body: (declaration_list
    "{" @start
    "}" @end))

(class_specifier
  body: (field_declaration_list
  "{" @start
  "}" @end)
  (#set! role type)
)

(function_definition
  body: (compound_statement
    "{" @start
    "}" @end)
  (#set! role function)
)

(if_statement
  consequence: (compound_statement
    "{" @start
    "}" @end))
(if_statement
  alternative: (compound_statement
    "{" @start
    "}" @end))

(while_statement
  body: (compound_statement
    "{" @start
    "}" @end))

(do_statement
  body: (compound_statement
    "{" @start
    "}" @end))
    
(for_statement
  body: (compound_statement
    "{" @start
    "}" @end))

(compound_statement
  (compound_statement
    "{" @start
    "}" @end))

(try_statement
  body: (compound_statement
    "{" @start
    "}" @end))
(catch_clause
  body: (compound_statement
    "{" @start
    "}" @end))