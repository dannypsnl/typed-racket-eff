#lang typed/racket
(provide Eff
         effs
         effect
         with-eff
         define/eff)
(require "arrow-ty.rkt"
         type-expander
         (for-syntax syntax/parse
                     syntax/stx
                     racket/syntax))

; Usage: (Eff A (effs log raise))
;
; this represents a type A use effects log & raise.
(define-type (Eff A I)
  (-> I A))

(define-type-expander effs
  (syntax-parser
    [(_ eff*:id ...)
     (define sig*
       (stx-map (λ (e)
                  (define sign (eval e))
                  #`[#,e #,sign])
                #'(eff* ...)))
     #`(Object #,@sig*)]))

(define-syntax effect
  (syntax-parser
    #:datum-literals (:)
    [(_ name:id : T)
     #`(begin
         (define-for-syntax name #'T)
         (define name : #,(tag-type #'T)
           (make-continuation-prompt-tag '#,(syntax->datum #'name))))]))

(define-syntax with-eff
  (syntax-parser
    #:datum-literals (:)
    [(_ : T_out {eff*:id ...} body*:expr ... body:expr)
     (define obj-name (generate-temporary 'obj))
     (define def*
       (stx-map (λ (e)
                  (define sign (eval e))
                  #`(define (#,e [x : #,(in-type sign)]) : #,(out-type sign)
                      (send #,obj-name #,e x)))
                #'(eff* ...)))

     #`(λ ([#,obj-name : (effs eff* ...)]) : T_out
         #,@def*
         body* ... body)]))
(define-syntax define/eff
  (syntax-parser
    #:datum-literals (:)
    [(_ (f:id [x:id : T] ...) : T_out {eff*:id ...}
        body*:expr ... body:expr)
     #'(define (f [x : T] ...)
         (with-eff : T_out {eff* ...}
           body* ... body))]))
