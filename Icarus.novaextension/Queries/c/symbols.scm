; Types

(struct_specifier
  name: (type_identifier) @name
  body: (_)
  (#set! role struct)) @subtree

(union_specifier
  name: (type_identifier) @name
  body: (_)
  (#set! role union)) @subtree

(enum_specifier
  name: (type_identifier) @name
  body: (_)
  (#set! role enum))

(type_definition
  declarator: (type_identifier) @name
  (#set! role type)) @subtree

(declaration
  declarator: (function_declarator
    declarator: (identifier) @name)
  (#set! role function-or-method)) @subtree

; Functions

(function_definition
  declarator: (function_declarator
    declarator: (identifier) @name)
  (#set! role function-or-method)) @subtree

(function_definition
  declarator: (pointer_declarator
    declarator: (function_declarator
      declarator: (identifier) @name))
  (#set! role function-or-method)) @subtree

; Preprocessor

(preproc_function_def
  name: (identifier) @name
  (#set! role function)) @subtree
