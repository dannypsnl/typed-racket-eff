#lang racket
(require racket/control
         "with.rkt")

(define effect-log (make-continuation-prompt-tag 'log))

(define (log msg)
  (call/cc (λ (k)
             (abort/cc effect-log k msg))))

(define (f)
  (log 1)
  (log 2)
  (log 3)
  (log 4)
  (log 5))

(with [effect-log (λ (resume v)
                 (println v)
                 (resume))]
      (f))
