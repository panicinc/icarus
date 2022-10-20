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
