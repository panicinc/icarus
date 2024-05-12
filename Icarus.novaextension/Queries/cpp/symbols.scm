; Types

(namespace_definition
  name: (_) @name
  (#set! role type)) @subtree

(class_specifier
  name: (type_identifier) @name
  (#set! role class)) @subtree

; Functions and methods

(field_declaration_list
  (declaration
    declarator: (function_declarator
      declarator: (identifier) @name)) @subtree
  (#set! role function-or-method))

(field_declaration_list
  (declaration
    declarator: (function_declarator
      declarator: (destructor_name) @name)) @subtree
  (#set! role destructor))

(field_declaration_list
  (field_declaration
    declarator: (function_declarator
      declarator: (field_identifier) @name)) @subtree
  (#set! role function-or-method))

(field_declaration_list
  (function_definition
    declarator: (function_declarator
      declarator: (field_identifier) @name)) @subtree
  (#set! role function-or-method))
  
(field_declaration_list
  (field_declaration
    declarator: (field_identifier) @name) @subtree
  (#set! role property))

(declaration
  declarator: (function_declarator
    declarator: (qualified_identifier
      name: (identifier) @name) @displayName)
  (#set! role function-or-method)) @subtree

(function_definition
  declarator: (function_declarator
    declarator: (qualified_identifier
      name: (identifier) @name) @displayName)
  (#set! role function-or-method)) @subtree

(function_definition
  declarator: (function_declarator
    declarator: (qualified_identifier
      name: (destructor_name) @name) @displayName)
  (#set! role destructor)) @subtree
