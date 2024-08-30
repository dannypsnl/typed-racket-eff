#lang typed/racket
(require "arrow-ty.rkt"
         "eff.rkt"
         "with-eff-handlers.rkt")

(effect log : (-> String Void))
(define/eff (f [x : String]) : Void { log }
  (log "1")
  (log "2")
  (log x))
(with-eff/handlers ([log (λ ([resume : (-> Void Void)]
                             [v : String]) : Void
                           (printf "~a~n" v)
                           (resume (void)))])
  (f "msg"))


(effect raise : (-> String Void))
(define (g)
  (with-eff : Void { raise log }
    (log "hello")
    (raise "gg")
    (log "world")))

(with-eff/handlers ([log (λ ([resume : (-> Void Void)]
                             [v : String]) : Void
                           (printf "~a~n" v)
                           (resume (void)))]
                    [raise (λ ([resume : (-> Void Void)]
                               [err : String]) : Void
                             (printf "got error: ~a~n" err))])
  (g))
