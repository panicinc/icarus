; ADT definitions

((struct_item
  name: (type_identifier) @name) @subtree
  (#set! role "struct")
)

((enum_item
  name: (type_identifier) @name) @subtree
  (#set! role "enum")
)

((union_item
  name: (type_identifier) @name) @subtree
  (#set! role "union")
)

; type aliases

((type_item
  name: (type_identifier) @name) @subtree
  (#set! role "type")
)

; method definitions

((declaration_list
  (function_item
    name: (identifier) @name) @subtree)
  (#set! role "method")
)

; function definitions

((function_item
  name: (identifier) @name) @subtree
  (#set! role "function")
  (#not-has-parent? @subtree "declaration_list")
)

; trait definitions
((trait_item
  name: (type_identifier) @name) @subtree
  (#set! role "interface")
)

; module definitions
((mod_item
  name: (identifier) @name) @subtree
  (#set! role "type")
)

; macro definitions

((macro_definition
  name: (identifier) @name) @subtree
  (#set! role "function")
)

; implementations

((impl_item
  trait: (type_identifier) @name) @subtree
  (#set! role "type")
)

((impl_item
  type: (type_identifier) @name
  !trait) @subtree
  (#set! role "type")
)
