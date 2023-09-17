(method_declaration
  . [
    "+"
    "-"
  ] @result .
  (method_type)? .
  (identifier) @result . (method_parameter ":" @result)?)
(method_declaration
  (method_type)? .
  (identifier) (method_parameter ":")
  (identifier) @result . (method_parameter ":" @result))
