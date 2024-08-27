#lang racket
(provide effect-file fread)
(require racket/control
         "with.rkt")

(define effect-file (make-continuation-prompt-tag 'file))

(define (fread)
  (call/cc (λ (k) (abort/cc effect-file k))))

(module+ main
  (define (f)
    (define in (fread))
    (println in))

  (define (with-file path action)
    (define in (open-input-file	path))
    (with [effect-file (λ (resume) (resume (read-line in)))]
      (action))
    (close-input-port in))

  (with-file "README.md" f)
  )
