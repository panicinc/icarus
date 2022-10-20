(struct_specifier
  body: (field_declaration_list
    "{" @start
    "}" @end
  )
  (#set! role type)
)
(union_specifier
  body: (field_declaration_list
    "{" @start
    "}" @end
  )
  (#set! role type)
)
(enum_specifier
  body: (enumerator_list
    "{" @start
    "}" @end
  )
  (#set! role type)
)

(function_definition
  body: (compound_statement
    "{" @start
    "}" @end
  )
  (#set! role function)
)

(for_statement
  body: (compound_statement
    "{" @start
    "}" @end
  )
)
(while_statement
  body: (compound_statement
    "{" @start
    "}" @end
  )
)
(do_statement
  body: (compound_statement
    "{" @start
    "}" @end
  )
)

(if_statement
  consequence: (compound_statement
    "{" @start
    "}" @end
  )
)
(if_statement
  alternative: (compound_statement
    "{" @start
    "}" @end
  )
)

(declaration
  declarator: (init_declarator
    value: (initializer_list
      "{" @start
      "}" @end
    )
  )
)