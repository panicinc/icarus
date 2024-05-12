(conditional
  condition: (ifeq_directive ")" @start)
  "endif" @end)
(conditional
  condition: (ifneq_directive ")" @start)
  "endif" @end)
(conditional
  condition: (ifdef_directive variable: (_) @start)
  "endif" @end)
(conditional
  condition: (ifdef_directive variable: (_) @start)
  "endif" @end)

((rule ":" @start) @end.after
  (#set! role "function")
  (#set! scope.byLine))
