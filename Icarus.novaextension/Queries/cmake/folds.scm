(if_condition
  (if_command) @start
  (elseif_command)? @end
  (else_command)? @end
  (endif_command) @end
  (#set! scope.byLine))
(if_condition
  (elseif_command) @start
  (else_command)? @end
  (endif_command) @end
  (#set! scope.byLine))
(if_condition
  (else_command) @start
  (endif_command) @end
  (#set! scope.byLine))
(foreach_loop
  (foreach_command) @start
  (endforeach_command) @end
  (#set! scope.byLine))
(while_loop
  (while_command) @start
  (endwhile_command) @end
  (#set! scope.byLine))
(function_def
  (function_command) @start
  (endfunction_command) @end
  (#set! scope.byLine)
  (#set! role "function"))
(macro_def
  (macro_command) @start
  (endmacro_command) @end
  (#set! scope.byLine)
  (#set! role "function"))
(block_def
  (block_command) @start
  (endblock_command) @end
  (#set! scope.byLine))
