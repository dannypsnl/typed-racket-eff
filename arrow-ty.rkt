#lang typed/racket
(provide (for-syntax tag-type
                     resume-type
                     in-type*
                     out-type))
(require (for-syntax syntax/parse))

(begin-for-syntax
  (define (tag-type T)
    (syntax-parse T
      #:datum-literals (->)
      [(-> In ... Out)
       #'(Prompt-Tagof Any
                       (-> (-> Out Void) In ... Void))]))
  (define (resume-type T)
    (syntax-parse T
      #:datum-literals (->)
      [(-> In ... Out)
       #'(-> Out Void)]))
  (define (in-type* T)
    (syntax-parse T
      #:datum-literals (->)
      [(-> In ... Out)
       #'(In ...)]))
  (define (out-type T)
    (syntax-parse T
      #:datum-literals (->)
      [(-> In ... Out)
       #'Out])))
