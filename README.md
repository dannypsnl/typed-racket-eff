# typed/racket + eff

The project integrate effect/handler system with typed/racket, the basic example is

```racket
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

As desired behaviour of an effect system.

## Details

The program
1. use `call/prompt` to insert prompt tag
2. `call/cc` in `f` captures the current continuation as `k`
3. `abort/cc` forward a value and `k` as `resume` to handler of tag
