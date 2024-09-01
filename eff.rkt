#lang typed/racket
(provide Eff effs
         effect
         effect-out
         with-eff
         define/eff)
(require "arrow-ty.rkt"
         type-expander
         (for-syntax syntax/parse
                     racket/provide-transform
                     syntax/stx
                     racket/syntax))

(define-syntax effect-out
  (make-provide-transformer
   (lambda (stx modes)
     (unless (or (null? modes)
                 (equal? '(0) modes))
       (raise-syntax-error
        #f
        "allowed only for relative phase level 0"
        stx))
     (syntax-parse stx
       [(_ eff:id)
        (list (export #'eff #'eff 0 #f #'eff)
              (export #'eff #'eff 1 #f #'eff))]))))

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
