(protocol_declaration
  name: (identifier) @name
  (#set! role interface)
) @subtree

(class_interface
  name: (identifier) @name
  (#set! role class)
) @subtree
(class_implementation
  name: (identifier) @name
  (#set! role class)
) @subtree

(category_interface
  name: (identifier) @name
  (#set! role category)
) @subtree
(category_implementation
  name: (identifier) @name
  (#set! role category)
) @subtree

(property_declaration
  declarator: [
    (pointer_declarator
      declarator: (identifier) @name)
    (block_declarator
      declarator: (identifier) @name)
    (identifier) @name
  ]
  (#set! role property)
) @subtree

(method_declaration
  (#set! name.query "objc/methodDeclarationName.scm")
  (#set! role method)
) @subtree @name.target

(method_definition
  (#set! name.query "objc/methodDefinitionName.scm")
  (#set! role method)
) @subtree @name.target