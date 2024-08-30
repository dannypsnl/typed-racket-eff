#lang typed/racket
(provide effect
         define/eff
         with-eff
         with-eff/handlers)
(require "arrow-ty.rkt"
         "eff.rkt"
         "with-eff-handlers.rkt")

(module+ main
  (effect log : (-> String Void))
  (define/eff (f [x : String]) : Void { log }
    (log "1")
    (log "2")
    (log x))
  (with-eff/handlers ([log (λ ([resume : (-> Void Void)]
                               [v : String]) : Void
                             (printf "log: ~a~n" v)
                             (resume (void)))])
    (f "msg"))


  (effect raise : (-> String Void))
  (define (g)
    (with-eff : Void { raise log }
      (log "hello")
      (raise "gg")
      (log "world")))

  (define/eff (h) : Void { raise }
    (with-eff/handlers ([raise #:forward]
                        [log (λ ([resume : (-> Void Void)]
                                 [v : String]) : Void
                               (printf "log(h): ~a~n" v)
                               (resume (void)))])
      (g)))

  (with-eff/handlers ([raise (λ ([resume : (-> Void Void)]
                                 [err : String]) : Void
                               (printf "got error: ~a~n" err))])
    (h))
  )