(comment) @comment
(string
  "\"" @string.delimiter.left
  "\"" @string.delimiter.right
) @string
(escape_sequence) @string.escape
(format_sequence) @string.escape
"=" @operator
