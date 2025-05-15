(comment) @comment

(string
  . "\"" @string.delimiter.left
  "\"" @string.delimiter.right .
  ) @string

[
  ":"
  "="
  ":="
  "::="
  "?="
  "+="
  "!="
] @operator

[
  "$"
  "@"
  "%"
  "<"
  "?"
  "^"
  "+"
  "/"
  "*"
] @keyword

[
  "("
  ")"
  "{"
  "}"
] @punctuation.bracket

[
  ","
] @punctuation.delimiter

(include_directive "include" @keyword)
(include_directive "-include" @keyword)
(export_directive "export" @keyword)
(define_directive "define" @keyword)
(define_directive "endef" @keyword)
(override_directive "override" @keyword)

(ifeq_directive "ifeq" @keyword)
(ifneq_directive "ifneq" @keyword)
(ifdef_directive "ifdef" @keyword)
(ifndef_directive "ifndef" @keyword)
(elsif_directive "else" @keyword)
(else_directive "else" @keyword)
(conditional "endif" @keyword)

(variable_assignment
  name: (word) @identifier.key)
(VPATH_assignment
  name: "VPATH" @identifier.key)

(variable_reference ["$" "$$"] @keyword)
(variable_reference (word) @identifier.variable)

(rule
  (targets (word) @identifier.function))
(rule
  (targets (concatenation (word) @identifier.function)))

(function_call "$" @keyword)
(function_call
  function: [
    "subst"
    "patsubst"
    "strip"
    "findstring"
    "filter"
    "filter-out"
    "sort"
    "word"
    "words"
    "wordlist"
    "firstword"
    "lastword"
    "dir"
    "notdir"
    "suffix"
    "basename"
    "addsuffix"
    "addprefix"
    "join"
    "wildcard"
    "realpath"
    "abspath"
    "error"
    "warning"
    "info"
    "origin"
    "flavor"
    "foreach"
    "if"
    "or"
    "and"
    "call"
    "eval"
    "file"
    "value"
  ] @identifier.function)

(shell_function "$" @keyword)
(shell_function [
    "shell"
  ] @identifier.function)
