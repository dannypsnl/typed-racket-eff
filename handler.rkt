#lang typed/racket
(provide fun)
(require "arrow-ty.rkt"
         type-expander
         (for-syntax syntax/parse
                     syntax/stx
                     racket/syntax))

(define-syntax fun
  (syntax-parser
    #:datum-literals (=>)
    [(_ arg:id => body ...+)
    #'(λ (resume arg)
        (resume ((λ (arg) body ...) arg)))]))
