(class_body
  "{" @start
  "}" @end)

(enum_class_body
  "{" @start
  "}" @end)

(protocol_declaration
  body: (protocol_body
    "{" @start
    "}" @end))

(function_body
  "{" @start
  "}" @end)

(lambda_literal
  "{" @start
  "}" @end)
    
(do_statement
  "{" @start
  "}" @end)
      
(catch_block
  "{" @start
  "}" @end)
  
(guard_statement
  "{" @start
  "}" @end)
  
(for_statement
  "{" @start
  "}" @end)
  
(if_statement
  "{" @start
  "}" @end)

(while_statement
  "{" @start
  "}" @end)

(repeat_while_statement
  "{" @start
  "}" @end)
  
(switch_statement
  "{" @start
  "}" @end)

((switch_entry
  ":" @start) @end.after
 (#set! fold.byLine)
)

(array_literal
  "[" @start
  "]" @end)

(dictionary_literal
  "[" @start
  "]" @end)
