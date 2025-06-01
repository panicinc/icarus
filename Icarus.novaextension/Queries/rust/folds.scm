((block "{" @start "}" @end)
(#set! role block))

((function_item 
  body: (block "{" @start "}" @end))
(#set! role "function"))

((struct_item
  body: (field_declaration_list "{" @start "}" @end))
(#set! role "type"))

((struct_item
  body: (ordered_field_declaration_list "(" @start ")" @end))
(#set! role "type"))

((enum_item
  body: (enum_variant_list "{" @start "}" @end))
(#set! role "type"))

((impl_item
  body: (declaration_list "{" @start "}" @end))
(#set! role "type"))

((trait_item
  body: (declaration_list "{" @start "}" @end))
(#set! role "type"))
