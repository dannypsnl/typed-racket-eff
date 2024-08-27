#lang racket
(require racket/control
         (for-syntax syntax/parse))

(define log-tag (make-continuation-prompt-tag 'log))
(define-syntax (with stx)
  (syntax-parse stx
    [(with [tag handler] body)
     #'(call/prompt (λ () body)
                    tag
                    handler)]))

(define (log msg)
  (call/cc (λ (k)
             (abort/cc log-tag k msg))))

(define (f)
  (println 1)
  (log 2)
  (println 3)
  (log 4)
  (println 5))

(with [log-tag (λ (resume v)
                 (println v)
                 (resume))]
      (f))
