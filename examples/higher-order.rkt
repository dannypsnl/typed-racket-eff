#lang typed/racket
(require "../main.rkt")

(effect number-to-string : (-> Number String))

(define/eff (f [x : Number]) : String { number-to-string }
  (number-to-string x))

(: emap : (All (I A B)
               (-> (-> A (Eff B I))
                   (Listof A)
                   (Eff (Listof B) I))))
(define (emap f l)
  (λ (eff)
    (#{map @ B A} (λ (x) ((f x) eff)) l)))

(module+ main
  (with-eff/handlers ([number-to-string
                       (λ ([resume : (-> String Void)]
                           [v : Number])
                         (resume (format "~a" v)))])
    (emap f
          (list 1 2 3)))
  )
