#lang typed/racket
(provide effect effect-out
         Eff effs
         define/eff
         with-eff
         with-eff/handlers
         fun)
(require "eff.rkt"
         "with-eff-handlers.rkt"
         "handler.rkt")

(module+ test
  (require typed/rackunit)

  (effect escape : (-> Integer Void))
  (define/eff (f) : Void { escape }
    (escape 10))

  (with-eff/handlers ([escape (λ ([resume : (-> Void Void)]
                                  [v : Integer]) : Void
                                (check-equal? v 10)
                                (void))])
    (f))
  )
