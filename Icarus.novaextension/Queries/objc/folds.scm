; Types

(protocol_declaration
  "@protocol" .
  (identifier) @start
  (protocol_reference_list)? @start
  "@end" @end
  (#set! role type)
  (#set! scope.byLine))

(class_interface
  "@interface" .
  (identifier) @start
  superclass: (identifier)? @start
  (parameterized_arguments)? @start
  "@end" @end
  (#set! role type)
  (#set! scope.byLine))

(class_implementation
  "@implementation" .
  (identifier) @start
  "@end" @end
  (#set! role type)
  (#set! scope.byLine))

(instance_variables
  "{" @start
  "}" @end)

; Methods

(method_definition
  (compound_statement
    "{" @start
    "}" @end)
  (#set! role function))

; Literals

(array_literal
  . "@" . "[" @start
  "]" @end . )
(dictionary_literal
  . "@" . "{" @start
  "}" @end . )