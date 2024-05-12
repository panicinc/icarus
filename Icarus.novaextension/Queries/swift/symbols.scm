; Structs, enums, classes, and protocols
(class_declaration
  declaration_kind: "struct"
  name: (type_identifier) @name
  (#set! role struct)
) @subtree
(class_declaration
  declaration_kind: "enum"
  name: (type_identifier) @name
  (#set! role enum)
) @subtree
(class_declaration
  declaration_kind: "class"
  name: (type_identifier) @name
  (#set! role class)
) @subtree
(class_declaration
  declaration_kind: "actor"
  name: (type_identifier) @name
  (#set! role class)
) @subtree
(class_declaration
  declaration_kind: "extension"
  name: (user_type) @name
  (#set! role category)
) @subtree
(protocol_declaration
  name: (type_identifier) @name
  (#set! role interface)
) @subtree

; Initializers
(function_declaration
  name: "init" @name
 (#set! role constructor)
) @subtree

; Deinitializers
(deinit_declaration
  "deinit" @name
 (#set! role destructor)
) @subtree

; Functions and methods
(function_declaration
  ; A performance issue in Tree Sitter query creation is preventing use of the modifiers.
  ; (modifiers
  ;   [
  ;     (property_modifier "static")
  ;     (property_modifier "class")
  ;   ]
  ; )?
  name: (simple_identifier) @name
 ; (#set-by-case-eq! @_static role
 ;   "static" static-method
 ;   "class" static-method
 ;   function-or-method
 ; )
  (#set! role function-or-method)
) @subtree

; Properties
(class_body
  (property_declaration
  ; A performance issue in Tree Sitter query creation is preventing use of the modifiers.
    ; (modifiers
    ;   (property_modifier
    ;     ["static" "class"] @_static
    ;   )
    ; )?
    name: (pattern bound_identifier: (simple_identifier) @name)
   ; (#set-by-case-eq! @_static role
   ;   "static" static-property
   ;   "class" static-property
   ;   property
   ; )
   (#set! role property)
  ) @subtree
)
(enum_class_body
  (property_declaration
    ; A performance issue in Tree Sitter query creation is preventing use of the modifiers.
    ; (modifiers
    ;   [
    ;     (property_modifier "static")
    ;     (property_modifier "class")
    ;   ] @_static
    ; )?
    name: (pattern bound_identifier: (simple_identifier) @name)
   ; (#set-by-case-eq! @_static role
   ;   "static" static-property
   ;   "class" static-property
   ;   property
   ; )
    (#set! role property)
  ) @subtree
)

; Macros
((macro_declaration (simple_identifier) @name) @subtree
  (#set! role type)
)
