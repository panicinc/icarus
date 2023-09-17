; Types

(struct_specifier
  body: (field_declaration_list
    "{" @start
    "}" @end)
  (#set! role type))

(union_specifier
  body: (field_declaration_list
    "{" @start
    "}" @end)
  (#set! role type))

(enum_specifier
  body: (enumerator_list
    "{" @start
    "}" @end)
  (#set! role type))

; Functions

(function_definition
  body: (compound_statement
    "{" @start
    "}" @end)
  (#set! role function))

; Statements

(for_statement
  body: (compound_statement
    "{" @start
    "}" @end))

(while_statement
  body: (compound_statement
    "{" @start
    "}" @end))

(do_statement
  body: (compound_statement
    "{" @start
    "}" @end))

(if_statement
  consequence: (compound_statement
    "{" @start
    "}" @end))

(else_clause
  (compound_statement
    "{" @start
    "}" @end))

(declaration
  declarator: (init_declarator
    value: (initializer_list
      "{" @start
      "}" @end)))

(compound_statement
  (compound_statement
    "{" @start
    "}" @end))

; Preprocessor

((preproc_if
  "#if" @start
  alternative: (_)? @end
  "#endif" @end) @end.after
  (#set! scope.byLine))

((preproc_elif
  "#elif" @start
  alternative: (_)? @end) @end.after
  (#set! scope.byLine))

((preproc_ifdef
  ["#ifdef" "#ifndef"] @start
  alternative: (_)? @end
  "#endif" @end) @end.after
  (#set! scope.byLine))

((preproc_elifdef
  ["#elifdef" "#elifndef"] @start
  alternative: (_)? @end) @end.after
  (#set! scope.byLine))

((preproc_else
  "#else" @start) @end.after
  (#set! scope.byLine))
