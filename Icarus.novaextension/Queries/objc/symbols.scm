(protocol_declaration
  "@protocol" .
  (identifier) @name
  (#set! role interface)) @subtree

(class_interface
  "@interface" .
  (identifier) @name
  "("? @categoryOpen @name
  category: (identifier)? @name
  ")"? @categoryClose @name
  (#set-by-case-match! @categoryOpen role
    "\\(" category
    class)) @subtree

(class_implementation
  "@implementation" .
  (identifier) @name
  "("? @categoryOpen @name
  category: (identifier)? @name
  ")"? @categoryClose @name
  (#set-by-case-match! @categoryOpen role
    "\\(" category
    class)) @subtree

(property_declaration
  (struct_declaration
    (struct_declarator
      [
        (identifier) @name
        (pointer_declarator declarator: (identifier) @name)
        (pointer_declarator declarator: (pointer_declarator declarator: (identifier) @name))
        (block_pointer_declarator declarator: (identifier) @name)
        (function_declarator declarator: (parenthesized_declarator (block_pointer_declarator declarator: (identifier) @name)))
      ]))
  (#set! role property)) @subtree

(method_declaration
  (#set! name.query "objc/methodDeclarationName.scm")
  (#set! role method)) @subtree @name.target

(method_definition
  (#set! name.query "objc/methodDefinitionName.scm")
  (#set! role method)) @subtree @name.target