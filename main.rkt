#lang typed/racket
(provide effect
         Eff effs
         define/eff
         with-eff
         with-eff/handlers)
(require "eff.rkt"
         "with-eff-handlers.rkt")

(module+ test
  (require typed/rackunit)

  (effect escape : (-> Integer Void))
  (define/eff (f) : Void { escape }
    (escape 10))

  (with-eff/handlers ([escape (λ ([resume : (-> Void Void)]
                                  [v : Integer])
                                (check-equal? v 10)
                                (void))])
    (f))
  )
