#lang turnstile+
(provide 
  #%datum #%app λ
  #%module-begin #%top-interaction
  (type-out Void Number String →))

(define-base-type Void)
(define-base-type Number)
(define-base-type String)
(define-type-constructor → #:arity > 0)

; [primitive]
(define-typed-syntax #%datum
  [(_ . x:number) ≫
   -----
   [⊢ (#%datum- . x) ⇒ Number]]
  [(_ . x:string) ≫
   -----
   [⊢ (#%datum- . x) ⇒ String]])
; [LAM]
(define-typed-syntax (λ ([x:id : τ_in:type] ...) e) ≫
  [[x ≫ x- : τ_in.norm] ... ⊢ e ≫ e- ⇒ τ_out]
  -------
  [⊢ (λ- (x- ...) e-) ⇒ (→ τ_in.norm ... τ_out)])
; [APP]
(define-typed-syntax #%app
  [(_ void) ≫
    -----
    [⊢ (#%app- void-) ⇒ Void]]
  [(_ e_fn e_arg ...) ≫
    [⊢ e_fn ≫ e_fn- ⇒ (~→ τ_in ... τ_out)]
    [⊢ e_arg ≫ e_arg- ⇐ τ_in] ...
    --------
    [⊢ (#%app- e_fn- e_arg- ...) ⇒ τ_out]])

(module+ main
  ((λ ([x : Number]) x) 1)
  )
