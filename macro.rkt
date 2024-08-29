#lang typed/racket
(require (for-syntax syntax/parse
                     syntax/stx))

(define-syntax effect
  (syntax-parser
    #:datum-literals (:)
    [(_ name:id : T)
     (syntax-parse #'T
       [(-> In ... Out)
        #'(begin
            (begin-for-syntax
              (define name #'T))
            (define name : (Prompt-Tagof Any
                                         (-> (-> Out Void) In ... Void))
              (make-continuation-prompt-tag 'tag)))])]))
(effect log : (-> Number Number))

(define-syntax define/eff
  (syntax-parser
    #:datum-literals (:)
    [(_ (f:id [x:id : T] ...) : T_out {eff*:id ...}
        body*:expr ...+ body:expr)
     (define bind*
       (stx-map (λ (e)
                  (define sign (eval e))
                  #`[#,e : #,sign]) #'(eff* ...)))
     #`(define ((f #,@bind*) [x : T] ...) : T_out
         body* ... body)]))
(define/eff (f [x : String]) : Void { log }
  (println 1)
  (println (log 2))
  (println 3)
  (println (log 4))
  (println 5))

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


(let ([log-wrapper (λ ([n : Number])
                     (cast
                      (call/cc (λ ([k : (-> Number Void)])
                                 (abort/cc log k n)))
                      Number))])
  (call/prompt (λ () ((f log-wrapper) "Hello"))
               log
               (λ ([resume : (-> Number Void)]
                   [v : Number]) : Void
                 (println v)
                 (resume 10))
               )
  )
