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
  argument: (preproc_arg)? @processing.argument)
