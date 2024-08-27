#lang racket
(provide effect-raise raise)
(require racket/control
         "with.rkt")

(define effect-raise (make-continuation-prompt-tag 'raise))

(define (raise msg)
  (call/cc (λ (k)
             (abort/cc effect-raise msg))))

(module+ main
  (define (f)
    (println 1)
    (raise 'cannot-read-file-xxx)
    (println 2))

  (with [effect-raise (λ (err) (printf "got error: ~a~n" err))]
    (f))
  )
