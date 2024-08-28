#lang racket
(provide with)
(require racket/control
         (for-syntax syntax/parse
                     racket/match))

(define-syntax (with stx)
  (syntax-parse stx
    [(with-command (~seq [tag handler] ...)
       body:expr)
     (define (go l)
       (match l
         [(cons h t)
          (syntax-parse h
            [(tag handler)
             #`(call/prompt (λ () #,(go t))
                            tag
                            handler)])]
         [_ #'body]))

     (go (syntax->list #'((tag handler) ...)))]))
