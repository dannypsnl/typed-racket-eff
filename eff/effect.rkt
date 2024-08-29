#lang turnstile+
(extends "base.rkt")
(require racket/control)

(define-typed-syntax define
  #:datum-literals (:)
  [(_ x:id e) ≫
   [⊢ e ≫ e- ⇒ τ]
   #:with x- (generate-temporary #'x)
   --------
   [≻ (begin-
        (define-typed-variable-rename x ≫ x- : τ)
        (define- x- e-))]]
  [(_ (f:id [x:id : τ_in:type] ...) : τ_out:type e) ≫
    #:with f- (generate-temporary #'f)
    [[x ≫ x- : τ_in.norm] ... ⊢ e ≫ e- ⇐ τ_out]
    ------
    [≻ (begin-
         (define-typed-variable-rename f ≫ f- : (→ τ_in ... τ_out))
         (define- f- (λ- (x- ...) e-)))]])

(define-type-constructor with-eff #:arity > 1)
(define-base-type EFF)

; [Def Eff]
(define-typed-syntax define-effect
  #:datum-literals (:)
  [(_ tag (eff [x:id : τ_in:type] ...) : τ_out:type) ≫
    #:with eff- (generate-temporary #'eff)
    ------
    [≻ (begin-
         (define-typed-variable-rename eff ≫ eff- : (→ τ_in ... τ_out))
         (define- (eff- x ...)
           (call/cc (lambda (k) (abort/cc tag k x ...))))
         (define- tag (make-continuation-prompt-tag))
         )]
  ])

; [With Eff]
(define-syntax with
  (syntax-parser
    [(_ [tag handler] body)
     #'(call/prompt (λ- () body)
                    tag
                    handler)
     ]))

(module+ main
  (define-effect effect-log (log [msg : String]) : Void)

  (log "hello")
  (define (hello) : Void
    (void))

  (with [effect-log (λ (resume msg) (println msg))]
    (hello))
  )
