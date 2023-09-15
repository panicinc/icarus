(line_comment) @comment

(normal_command . (identifier) @identifier.function)

[
  "$"
  (if)
  (elseif)
  (else)
  (endif)
  (foreach)
  (endforeach)
  (while)
  (endwhile)
  (function)
  (endfunction)
  (macro)
  (endmacro)
  (block)
  (endblock)
] @keyword

(quoted_argument
  . "\"" @string.delimiter.left
  "\"" @string.delimiter.right) @string

((unquoted_argument) @value.boolean 
  (#eq? @value.boolean "OFF" "ON"))
((unquoted_argument) @identifier.type 
  (#eq? @identifier.type "BOOL" "FILEPATH" "PATH" "STRING" "INTERNAL"))
((unquoted_argument) @keyword 
  (#eq? @keyword "NOT" "AND" "OR"))
((unquoted_argument) @keyword 
  (#eq? @keyword "CACHE" "COMMAND" "DEFINED" "FORCE" "IN_LIST" "POLICY" "TARGET" "TEST"))
((unquoted_argument) @keyword 
  (#eq? @keyword "EXISTS" "IS_NEWER_THAN" "IS_DIRECTORY" "IS_SYMLINK" "IS_ABSOLUTE" "PATH_EQUAL"))
((unquoted_argument) @keyword 
  (#eq? @keyword "MATCHES" "LESS" "GREATER" "EQUAL" "LESS_EQUAL" "GREATER_EQUAL" "STRLESS" "STRGREATER" "STREQUAL" "STRLESS_EQUAL" "STRGREATER_EQUAL"))
((unquoted_argument) @keyword 
  (#eq? @keyword "VERSION_LESS" "VERSION_GREATER" "VERSION_EQUAL" "VERSION_LESS_EQUAL" "VERSION_GREATER_EQUAL"))
