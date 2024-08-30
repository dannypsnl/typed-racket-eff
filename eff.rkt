#lang typed/racket
(provide effect
         define/eff)
(require "arrow-ty.rkt"
         (for-syntax syntax/parse
                     syntax/stx))

(define-syntax effect
  (syntax-parser
    #:datum-literals (:)
    [(_ name:id : T)
     #`(begin
         (define-for-syntax name #'T)
         (define name : #,(tag-type #'T)
           (make-continuation-prompt-tag '#,(syntax->datum #'name))))]))

(define-syntax define/eff
  (syntax-parser
    #:datum-literals (:)
    [(_ (f:id [x:id : T] ...) : T_out {eff*:id ...}
        body*:expr ... body:expr)
     (define bind*
       (stx-map (λ (e)
                  (define sign (eval e))
                  #`[#,e : #,sign]) #'(eff* ...)))
     #`(define ((f [x : T] ...) #,@bind*) : T_out
         body* ... body)]))
