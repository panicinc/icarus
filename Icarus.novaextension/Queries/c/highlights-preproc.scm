; Preprocessor
(preproc_if
  [
    "#if"
    "#endif"
  ] @processing.directive
  condition: (_) @processing.argument)
(preproc_elif
  "#elif" @processing.directive
  condition: (_) @processing.argument)
(preproc_else
  "#else" @processing.directive)
(preproc_if
  "#endif" @processing.directive)
(preproc_ifdef
  [
    "#ifdef"
    "#ifndef"
  ] @processing.directive
  name: (identifier) @processing.argument)
(preproc_ifdef
  "#endif" @processing.directive)
(preproc_def
  "#define" @processing.directive
  name: (identifier) @processing.argument
  value: (preproc_arg)? @processing.argument)
(preproc_include
  "#include" @processing.directive
  path: (_) @string)
(preproc_function_def
  "#define" @processing.directive
  name: (identifier) @processing.argument
  parameters: (preproc_params) @processing.argument
  value: (preproc_arg)? @processing.argument)
(preproc_call
  directive: (preproc_directive) @processing.directive
  argument: (preproc_arg)? @processing.argument
  (#not-eq? @processing.directive "#pragma"))
(preproc_call
  directive: (preproc_directive) @processing.directive
  argument: (preproc_arg)? @processing.argument
  (#eq? @processing.directive "#pragma")
  (#not-match? @processing.argument "^\\s+mark\\s+"))
(preproc_call 
  directive: (preproc_directive) @_directive
  argument: (preproc_arg) @_argument @comment.doctag
  (#eq? @_directive "#pragma")
  (#match? @_argument "^\\s+mark\\s+")) @comment
(preproc_defined
  "defined" @processing.directive)

((preproc_arg) @processing.argument.string
 (#match? @processing.argument.string "^\".*?\"$"))

; Parsing C literals using regex... longest sigh ever...
((preproc_arg) @value.number
  (#match? @value.number "(?x)^\
    \\s* \
    -? #negate \
    ( \
      # Integers \
      ( \
        ( \
          (0[0-7]*) #oct \
          | (0[bB][01]+) #bin \
          | (0[xX][0-9a-fA-F]+) #hex \
          | ([1-9][0-9]*) #dec \
        ) \
        ( \
          ([uU]([lLzZ]|ll|LL)?) \
          | (([lLzZ]|ll|LL)[uU]?) \
        )? \
      ) \
      # Floats \
      | \
      ( \
        ( \
          [0-9]+[eE](\\+|\\-)?[0-9]* #1e10 \
          | [0-9]+\.[0-9]*([eE](\\+|\\-)?[0-9]+)? #1.0e10 \
          | 0[xX][0-9]+[eE](\\+|\\-)?[0-9]* #1e10 \
          | 0[xX][0-9a-fA-F]+\.[0-9a-fA-F]*([pP](\\+|\\-)?[0-9]+)? #0x1.0e10 \
        ) \
        [fFlL]? \
      ) \
    ) \
    \\s* \
  $")
)
