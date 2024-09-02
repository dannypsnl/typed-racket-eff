#lang scribble/manual
@require[@for-label[typed-racket-eff
                    typed/racket/base]]

@title[#:tag "guide"]{Guide}

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
where @code{"world"} will not get printed, this is because the handler of @code{raise} didn't @code{resume} back to @code{f},
this is how the concept of exception get implemented in the effect handler system.
If we remove @code{[log ...]} in @code{with-eff/handlers}, the type checker will complain
@centered{
Type Checker: type mismatch;
 object lacks expected method `log' in: (with-eff/handlers ((raise (λ ((resume : (-> Void Void)) (err : String)) : Void (printf "got error: ~a~n" err)))) (f))
}
as desired behaviour of an effect system.

@section{Forward effect}

If you don't want to handle an effect immediately, use @code{#:forward} (assuming @code{f} use @code{log} and @code{raise})
@racketblock[
(define/eff (g) : Void { raise }
  (with-eff/handlers ([raise #:forward]
                      [log (λ ([resume : (-> Void Void)]
                               [v : String]) : Void
                             (printf "log(g): ~a~n" v)
                             (resume (void)))])
    (f)))
 ]

The function @code{g} handle the @code{log} effect, and let @code{f} use it's @code{raise}.

@section{Finally}

Use @code{#:finally} handler to ensure something will run after body clause.
@racketblock[
(effect fread : (-> Void String))

(define/eff (f) : Void { fread }
  (println (fread (void))))

(define in (open-input-file "file.rkt"))
(with-eff/handlers ([fread (λ ([resume : (-> String Void)]
                               [_ : Void])
                             (read-line in))])
  #:finally (λ () (close-input-port in))
  (f))
 ]

@section{Higher-order effect}

The higher-order effect can be done by use @code{Eff} type and the effect object,
then passing current effect object @code{eff} to the invoked function,
but the API is still sharp, it's easy to forget the pattern
@code{(λ (args ...) ((f args ...) eff))}.

@racketblock[
(effect number-to-string : (-> Number String))

(define/eff (f [x : Number]) : String { number-to-string }
  (number-to-string x))

(: emap : (All (I A B)
               (-> (-> A (Eff B I))
                   (Listof A)
                   (Eff (Listof B) I))))
(define (emap f l)
  (λ (eff)
    ({inst map B A} (λ (x) ((f x) eff)) l)))

(with-eff/handlers ([number-to-string
                     (λ ([resume : (-> String Void)]
                         [v : Number])
                       (resume (format "~a" v)))])
  (emap f
        (list 1 2 3)))
 ]
