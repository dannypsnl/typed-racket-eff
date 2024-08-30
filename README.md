# typed/racket + eff

The project integrate effect/handler system with [typed/racket](https://docs.racket-lang.org/ts-reference/index.html).

## Installation

```sh
raco pkg install typed-racket-eff
```

## Example

```racket
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
 object lacks expected method `log'
  in: #%module-begin
  location...:
   main.rkt:1:6
  context...:
   /Applications/Racket v8.12/share/pkgs/typed-racket-lib/typed-racket/typecheck/tc-toplevel.rkt:481:0: type-check
   .../private/parse-interp.rkt:643:50
   /Applications/Racket v8.12/share/pkgs/typed-racket-lib/typed-racket/tc-setup.rkt:115:12
   /Applications/Racket v8.12/share/pkgs/typed-racket-lib/typed-racket/typed-racket.rkt:22:4
```

as desired behaviour of an effect system.

## Forward effect

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

## Limitation

To generate proper `call/prompt` and `abort/cc`, every effect handler can only take one input type, so if you want to transfer several arguments, use structure to wrap them.

## Details

The program

1. use `call/prompt` to insert prompt tag
2. `call/cc` in `f` captures the current continuation as `k`
3. `abort/cc` forward a value and `k` as `resume` to handler of tag
