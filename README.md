# typed/racket + eff

The project integrate effect/handler system with [typed/racket](https://docs.racket-lang.org/ts-reference/index.html).

## Installation

```sh
raco pkg install typed-racket-eff
```

## Details

The program

1. use `call/prompt` to insert prompt tag
2. `call/cc` in `f` captures the current continuation as `k`
3. `abort/cc` forward a value and `k` as `resume` to handler of tag
