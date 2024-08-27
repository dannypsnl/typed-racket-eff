#lang racket
(require racket/control
         (for-syntax syntax/parse))
(provide with)

(define-syntax (with stx)
  (syntax-parse stx
    [(with [tag handler] body)
     #'(call/prompt (λ () body)
                    tag
                    handler)]))
