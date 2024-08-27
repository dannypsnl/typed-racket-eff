#lang racket
(require racket/control)

(define tag (make-continuation-prompt-tag 'tag))

(define (f)
  (println 1)
  (call/cc (lambda (k) (abort/cc tag k 2)))
  (println 3)
  (call/cc (lambda (k) (abort/cc tag k 4)))
  (println 5))

(call/prompt f
             tag
             (lambda (resume v)
               (println v)
               (resume)))
