#lang racket
(provide effect-log log)
(require racket/control
         "with.rkt")

(define effect-log (make-continuation-prompt-tag 'log))

(define (log msg)
  (call/cc (λ (k)
             (abort/cc effect-log k msg))))

(module+ main
  (require "effect-raise.rkt")
  (define (f)
    (log 1)
    (log 2)
    (log 3)
    (raise 'fail)
    (log 4)
    (log 5))

  (with [effect-raise (λ (err) (printf "got error: ~a~n" err))]
        [effect-log (λ (resume v)
                      (println v)
                      (resume))]
        (f))
  )
