#lang typed/racket
(require (for-syntax syntax/parse))

(begin
  #;(begin-for-syntax
      ())

  (: effect-log : (Prompt-Tagof Any (-> (-> Number Void) Number Void)))
  (define effect-log (make-continuation-prompt-tag 'tag)))

(define-syntax define/eff
  (syntax-parser
    #:datum-literals (:)
    [(_ (f:id [x:id : T] ...) : T_out {[effs:id : T*] ...}
        body*:expr ...+ body:expr)
     (println #'(effs ...))
     #'(define ((f [effs : T*] ...) [x : T] ...) : T_out
         body* ... body
         )
     ]))
(define/eff (f [x : String]) : Void { [log : (-> Number Number)] }
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


(let ([log (λ ([n : Number])
             (cast
              (call/cc (λ ([k : (-> Number Void)])
                         (abort/cc effect-log k n)))
              Number))])
  (call/prompt (λ () ((f log) "Hello"))
               effect-log
               (λ ([resume : (-> Number Void)]
                   [v : Number]) : Void
                 (println v)
                 (resume 10))
               )
  )

