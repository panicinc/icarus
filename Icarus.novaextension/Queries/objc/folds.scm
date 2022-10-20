(protocol_declaration
  name: (identifier) @start
  (protocol_qualifiers)? @start
  "@end" @end
  (#set! role type)
  (#set! scope.byLine)
)

(class_interface
  name: (identifier) @start
  (superclass_reference)? @start
  (protocol_qualifiers)? @start
  "@end" @end
  (#set! role type)
  (#set! scope.byLine)
)
(class_implementation
  name: (identifier) @start
  "@end" @end
  (#set! role type)
  (#set! scope.byLine)
)

(category_interface
  ")" @start
  (protocol_qualifiers)? @start
  "@end" @end
  (#set! role type)
  (#set! scope.byLine)
)
(category_implementation
  ")" @start
  "@end" @end
  (#set! role type)
  (#set! scope.byLine)
)

(method_definition
  body: (compound_statement
    "{" @start
    "}" @end)
  (#set! role function)
)

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
  (compound_statement
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

(if_statement
  consequence: (compound_statement
    "{" @start
    "}" @end))
(if_statement
  alternative: (compound_statement
    "{" @start
    "}" @end))
(if_statement
  consequence: (compound_statement
    (compound_statement
      "{" @start
      "}" @end)))

(array_expression
  . "@" . "[" @start
  "]" @end . )
(dictionary_expression
  . "@" . "{" @start
  "}" @end . )

(declaration
  declarator: (init_declarator
    value: (initializer_list
      "{" @start
      "}" @end)))