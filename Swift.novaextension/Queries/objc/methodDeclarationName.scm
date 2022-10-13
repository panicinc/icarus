(method_declaration
  scope: [
    (class_scope)
    (instance_scope)
  ] @result)
(method_declaration
  selector: (identifier) @result)
(method_declaration
  selector: (keyword_selector
      (keyword_declarator
        keyword: (identifier) @result))
  (#append! @result ":"))