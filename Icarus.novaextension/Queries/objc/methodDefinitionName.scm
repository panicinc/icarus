(method_definition
  . [
    "+"
    "-"
  ] @result .
  (method_type)? .
  (identifier) @result . (method_parameter ":" @result)?)
(method_definition
  (method_type)? .
  (identifier) (method_parameter ":")
  (identifier) @result . (method_parameter ":" @result))
