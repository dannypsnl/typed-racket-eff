#lang racket
(require racket/control)

(define tag (make-continuation-prompt-tag 'tag))

(define (f)
  (println 1)
  (define r (call/cc (lambda (k) (abort/cc tag k 2))))
  (println r)
  (println 3)
  (define r2 (call/cc (lambda (k) (abort/cc tag k 4))))
  (println r2)
  (println 5))

(call/prompt f
             tag
             (lambda (resume v)
               (println v)
               (resume 'back)))
