#lang racket
(provide 
  ; forms
  #%datum #%app λ
  ; types
  Number →)
(require turnstile)

(define-base-type Number)
(define-type-constructor → #:arity > 0)

; [primitive]
(define-typed-syntax #%datum
  [(_ . x:number) ≫
   ------------------
   [⊢ (#%datum- . x) ⇒ Number]]
  )
; [LAM]
(define-typed-syntax (λ ([x:id : τ_in:type] ...) e) ≫
  [[x ≫ x- : τ_in.norm] ... ⊢ e ≫ e- ⇒ τ_out]
  -------
  [⊢ (λ- (x- ...) e-) ⇒ (→ τ_in.norm ... τ_out)])
; [APP]
(define-typed-syntax (#%app e_fn e_arg ...) ≫
  [⊢ e_fn ≫ e_fn- ⇒ (~→ τ_in ... τ_out)]
  [⊢ e_arg ≫ e_arg- ⇐ τ_in] ...
  --------
  [⊢ (#%app- e_fn- e_arg- ...) ⇒ τ_out])

(module+ main
  ((λ ([x : Number]) x) 1)
  )
