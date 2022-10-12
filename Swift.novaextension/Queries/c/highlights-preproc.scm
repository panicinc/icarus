; Preprocessor
(preproc_if
  [
    "#if"
    "#endif"
  ] @processing.directive
  condition: (_) @processing.directive)
(preproc_elif
  "#elif" @processing.directive
  condition: (_) @processing.directive)
(preproc_else
  "#else" @processing.directive)
(preproc_if
  "#endif" @processing.directive)
(preproc_ifdef
  [
    "#ifdef"
    "#ifndef"
  ] @processing.directive
  name: (identifier) @processing.directive)
(preproc_ifdef
  "#endif" @processing.directive)
(preproc_def
  "#define" @processing.directive
  name: (identifier) @processing.directive
  value: (preproc_arg)? @processing.directive)
(preproc_include
  "#include" @processing.directive
  path: (_) @string)
(preproc_call
  directive: (preproc_directive) @processing.directive
  argument: (preproc_arg) @processing.directive)
