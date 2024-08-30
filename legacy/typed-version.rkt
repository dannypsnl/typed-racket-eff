#lang typed/racket
(require/typed racket/control
               [abort/cc
                ((Prompt-Tagof Any (-> (-> Number Void) Number Void))
                 (-> Number Void)
                 Number
                 -> Void)]
               [call/prompt
                ((-> Void)
                 (Prompt-Tagof Any (-> (-> Number Void) Number Void))
                 (-> (-> Number Void) Number Void)
                 -> Void)])

(: tag : (Prompt-Tagof Any (-> (-> Number Void) Number Void)))
(define tag (make-continuation-prompt-tag 'tag))

(: f : -> Void)
(define (f)
  (println 1)
  (println (call/cc (λ ([k : (-> Number Void)]) (abort/cc tag k 2))))
  (println 3)
  (println (call/cc (λ ([k : (-> Number Void)]) (abort/cc tag k 4))))
  (println 5))

(call/prompt f
             tag
             (λ ([resume : (-> Number Void)]
                 [v : Number])
               (println v)
               (resume 10)))
