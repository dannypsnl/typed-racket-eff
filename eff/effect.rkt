#lang turnstile+
(extends "base.rkt")
(require racket/control
         (for-syntax syntax/parse))

(define-type-constructor with-eff #:arity > 1)
(define-base-type EFF)

; [Def Eff]
(define-syntax define-effect
  (syntax-parser
    #:datum-literals (:)
    [(_ tag (eff [x:id : T_in] ...) : T_out)
     #'(begin
         (define tag (make-continuation-prompt-tag))
         (define-typed-variable-rename eff ≫ eff- : (→ T_in ... T_out))
         (define- (eff- x ...)
           (call/cc (lambda (k) (abort/cc tag k x ...)))))
     ]))

; [With Eff]
(define-syntax with
  (syntax-parser
    [(_ [tag handler] body)
     #'(call/prompt (lambda- () body)
                    tag
                    handler)
     ]))

(module+ main
  (define-effect effect-log (log [msg : String]) : Void)
  
  (def (hello) : Void
    (log "hello"))
  #;(check-type hello : (→ Void))

  (with [effect-log (λ (resume msg) (println msg))]
        (hello))
  )
