#lang scribble/manual
@require[@for-label[typed-racket-eff
                    typed/racket/base]]

@title[#:tag "api"]{API}

@defform[(effect name : type)]{
 Defines a new effect with @code{name}, and the @code{type} must be @code{(-> A B)}, correspondings to handler with parameters @code{resume : B -> Void} and @code{value : A}.
 For example,
 @racketblock[
 (effect raise : (-> String Void))
 ]
 @defsubform[(effect-out name)]{
  Provide the effect correctly, usage @code{(provide (effect-out name))}.
 }
}

@defform[(Eff T (effs ...))]{
 Decorate type @code{T} with effects, which will generate an arrow type that expected an effect object.
 @defsubform[(effs ...)]{
  Produce an @code{Object} where each method with an effect signature, this is the effect object type.
 }
}

@defform[(define/eff (name [param : T] ...) : T_out { e* ... } body* ... body)]{
 Equivalent to
 @racketblock[
  (define (name [param : T] ...)
    (with-eff : T_out { e* ... }
      body* ... body))
 ]
 @defsubform[(with-eff : T_out { e* ... } body* ... body)]{
  Create a lambda with type @code{Eff T_out (effs e* ...)}, and with body @code{body* ... body},
  i.e.
  @racketblock[
  (: (Eff T_out (effs e* ...)))
  (lambda (eff) body* ... body)
  ]
  This macro also bind a list of function to wrap @code{eff} object, e.g.
  @racketblock[
  (define (raise err) (send eff raise err))
  ]
  so you can invoke effect just like usual function.
 }
}

@defform[(with-eff/handlers (handlers ...) body)]{
 Execute @code{body} with effect handlers. For example,
 @racketblock[
 (effect log : (-> String Void))
 (effect raise : (-> String Void))

 (define/eff (f) : Void { raise log }
   (log "hello")
   (raise "failed")
   (log "world"))

 (with-eff/handlers ([log (λ ([resume : (-> Void Void)]
                              [v : String]) : Void
                             (printf "~a~n" v)
                             (resume (void)))]
                     [raise (λ ([resume : (-> Void Void)]
                                [err : String]) : Void
                             (printf "got error: ~a~n" err))])
   (f))
 ]
}
