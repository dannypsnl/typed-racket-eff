# typed/racket + eff

The project integrate effect/handler system with [typed/racket](https://docs.racket-lang.org/ts-reference/index.html).

## Installation

```sh
raco pkg install typed-racket-eff
```

## Example

```racket
#lang typed/racket
(require typed-racket-eff)

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
```

will print

```
hello
failed
```

then end. If we remove `[log ...]` from `with-eff/handlers`, the type checker will complain

```
Type Checker: type mismatch;
 object lacks expected method `log' in: (with-eff/handlers ((raise (λ ((resume : (-> Void Void)) (err : String)) : Void (printf "got error: ~a~n" err)))) (f))
```

as desired behaviour of an effect system.

### Forward effect

If you don't want to handle an effect immediately, use `#:forward` (assuming `f` use `log` and `raise`)

```racket
(define/eff (g) : Void { raise }
  (with-eff/handlers ([raise #:forward]
                      [log (λ ([resume : (-> Void Void)]
                               [v : String]) : Void
                             (printf "log(g): ~a~n" v)
                             (resume (void)))])
    (f)))
```

The function `g` handle the `log` effect, and let `f` use it's `raise`.

### Finally

Use `#:finally` handler to ensure something will run after `body` clause.

```racket
(effect fread : (-> Void String))

(define/eff (f) : Void { fread }
  (println (fread (void))))

(define in (open-input-file "file.rkt"))
(with-eff/handlers ([fread (λ ([resume : (-> String Void)]
                               [_ : Void])
                             (read-line in))])
  #:finally (λ () (close-input-port in))
  (f))
```

## Limitation

To generate proper `call/prompt` and `abort/cc`, every effect handler can only take one input type, so if you want to transfer several arguments, use structure to wrap them.

### Higher-order

The higher-order effect can be done by use `Eff` type and `eff` object, then by pass current `eff` object to the invoked function, but the API is still sharp, it's easy to forget `(λ (args ...) ((f args ...) eff))` pattern.

```racket
(effect number-to-string : (-> Number String))

(define/eff (f [x : Number]) : String { number-to-string }
  (number-to-string x))

(: emap : (All (I A B)
               (-> (-> A (Eff B I))
                   (Listof A)
                   (Eff (Listof B) I))))
(define (emap f l)
  (λ (eff)
    (#{map @ B A} (λ (x) ((f x) eff)) l)))

(with-eff/handlers ([number-to-string
                     (λ ([resume : (-> String Void)]
                         [v : Number])
                       (resume (format "~a" v)))])
  (emap f
        (list 1 2 3)))
```

## Details

The program

1. use `call/prompt` to insert prompt tag
2. `call/cc` in `f` captures the current continuation as `k`
3. `abort/cc` forward a value and `k` as `resume` to handler of tag
