#lang typed/racket
(require (for-syntax syntax/parse
                     syntax/stx
                     racket/match
                     )
         "arrow-ty.rkt")

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


(define-syntax (with stx)
  (syntax-parse stx
    [(_ (~seq [tag handler] ...)
        body:expr)
     (define (go l)
       (match l
         [(cons h t)
          (syntax-parse h
            [(tag handler)
             #`(call/prompt (λ () #,(go t))
                            tag
                            handler)])]
         [_ #'body]))

     (go (syntax->list #'((tag handler) ...)))]))

(define-syntax with-eff
  (syntax-parser
    [(_ ([tag handler] ...)
        body:expr)
     (define (go wrappers l)
       (match l
         [(cons h t)
          (syntax-parse h
            [(tag handler)
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
                 (call/prompt (λ ()
                                #,(go (cons #`(λ (#,@bind*)
                                                (cast
                                                 (call/cc (λ ([k : #,(resume-type t)])
                                                            (abort/cc tag k #,@x*)))
                                                 #,(out-type t))) wrappers)
                                      t))
                              tag
                              handler))])]
         [_ #`(body #,@wrappers)]))

     (go '() (syntax->list #'([tag handler] ...)))]))


(effect log : (-> String Void))
(define/eff (f [x : String]) : Void { log }
  (log "1")
  (log "2")
  (log x))

(with-eff ([log (λ ([resume : (-> Void Void)]
                    [v : String]) : Void
                  (printf "~a~n" v)
                  (resume (void)))])
  (f "Hello"))

(effect raise : (-> String Void))
(define/eff (g) : Void { raise }
  (raise "gg"))

(with-eff ([raise (λ ([resume : (-> Void Void)]
                      [err : String]) : Void
                    (printf "got error: ~a~n" err))])
  (g))
