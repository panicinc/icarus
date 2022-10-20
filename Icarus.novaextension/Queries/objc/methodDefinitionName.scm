(method_definition
  scope: [
    (class_scope)
    (instance_scope)
  ] @result)
(method_definition
  selector: (identifier) @result)
(method_definition
  selector: (keyword_selector
      (keyword_declarator
        keyword: (identifier) @result))
  (#append! @result ":"))