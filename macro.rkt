#lang typed/racket
(require (for-syntax syntax/parse
                     syntax/stx))

(define-for-syntax (tag-type T)
  (syntax-parse T
    [(-> In ... Out)
     #'(Prompt-Tagof Any
                     (-> (-> Out Void) In ... Void))]))
(define-for-syntax (resume-type T)
  (syntax-parse T
    [(-> In ... Out)
     #'(-> Out Void)]))
(define-for-syntax (in-type* T)
  (syntax-parse T
    [(-> In ... Out)
     #'(In ...)]))
(define-for-syntax (out-type T)
  (syntax-parse T
    [(-> In ... Out)
     #'Out]))

(define-syntax effect
  (syntax-parser
    #:datum-literals (:)
    [(_ name:id : T)
     #`(begin
         (begin-for-syntax
           (define name #'T))
         (define name : #,(tag-type #'T)
           (make-continuation-prompt-tag 'tag)))]))

(define-syntax define/eff
  (syntax-parser
    #:datum-literals (:)
    [(_ (f:id [x:id : T] ...) : T_out {eff*:id ...}
        body*:expr ...+ body:expr)
     (define bind*
       (stx-map (λ (e)
                  (define sign (eval e))
                  #`[#,e : #,sign]) #'(eff* ...)))
     #`(define ((f [x : T] ...) #,@bind*) : T_out
         body* ... body)]))

(define-syntax with-eff
  (syntax-parser
    [(_ [tag handler]
        body:expr)
     (define t (eval #'tag))
     (define x* (generate-temporaries (in-type* t)))
     (define bind* (stx-map (λ (x t) #`[#,x : #,t]) x* (in-type* t)))
     #`(begin
         (require/typed racket/control
                        [abort/cc
                         (#,(tag-type t)
                          #,(resume-type t)
                          #,@(in-type* t)
                          -> Void)]
                        [call/prompt
                         ((-> Void)
                          #,(tag-type t)
                          (-> #,(resume-type t) #,@(in-type* t) Void)
                          -> Void)])
         (let ([wrapper (λ (#,@bind*)
                              (cast
                               (call/cc (λ ([k : #,(resume-type t)])
                                          (abort/cc log k #,@x*)))
                               #,(out-type t)))])
           (call/prompt (λ () (body wrapper))
                        tag
                        handler)))]))


(effect log : (-> Number Number))

(define/eff (f [x : String]) : Void { log }
  (println 1)
  (println (log 2))
  (println 3)
  (println (log 4))
  (println 5))

(with-eff [log (λ ([resume : (-> Number Void)]
                   [v : Number]) : Void
                 (println v)
                 (resume 10))]
  (f "Hello"))
