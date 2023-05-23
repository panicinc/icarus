; Namespaces

(namespace_definition
  name: (_) @name
  (#set! role type)
) @subtree


; Classes

(class_specifier
  name: (type_identifier) @name
  (#set! role class)
) @subtree

(field_declaration_list
  (declaration
    declarator: (function_declarator
      declarator: (identifier) @name)) @subtree
  (#set! role function-or-method)
)

(field_declaration_list
  (declaration
    declarator: (function_declarator
      declarator: (destructor_name) @name)) @subtree
  (#set! role destructor)
)

(field_declaration_list
  (field_declaration
    declarator: (function_declarator
      declarator: (field_identifier) @name)) @subtree
  (#set! role function-or-method)
)
(field_declaration_list
  (function_definition
    declarator: (function_declarator
      declarator: (field_identifier) @name)) @subtree
  (#set! role function-or-method)
)
(field_declaration_list
  (field_declaration
    declarator: (field_identifier) @name) @subtree
  (#set! role property)
)


; Structs, enums, and unions

(struct_specifier
  name: (type_identifier) @name
  body: (_)
  (#set! role struct)
) @subtree

(union_specifier
  name: (type_identifier) @name
  body: (_)
  (#set! role union)
) @subtree

(enum_specifier
  name: (type_identifier) @name
  body: (_)
  (#set! role enum)
)

(type_definition
  declarator: (type_identifier) @name
  (#set! role type)
) @subtree


; Functions and methods

(declaration
  declarator: (function_declarator
    declarator: (qualified_identifier
      name: (identifier) @name
    ) @displayName
  )
  (#set! role function-or-method)
) @subtree

(declaration
  declarator: (function_declarator
    declarator: (identifier) @name
  )
  (#set! role function-or-method)
) @subtree

(function_definition
  declarator: (function_declarator
    declarator: (qualified_identifier
      name: (identifier) @name
    ) @displayName
  )
  (#set! role function-or-method)
) @subtree

(function_definition
  declarator: (function_declarator
    declarator: (identifier) @name
  )
  (#set! role function-or-method)
) @subtree

(function_definition
  declarator: (function_declarator
    declarator: (qualified_identifier
      name: (destructor_name) @name
    ) @displayName
  )
  (#set! role destructor)
) @subtree

(preproc_function_def
  name: (identifier) @name
  (#set! role function)
) @subtree
