#lang typed/racket
(require "../main.rkt")

(effect log : (-> String Void))
(effect raise : (-> String Void))

(define/eff (f [x : String]) : Void { log }
  (log "1")
  (log "2")
  (log x))

(define (g)
  (with-eff : Void { raise log }
    (log "hello")
    (raise "gg")
    (log "world")))

(define/eff (h) : Void { raise }
  (with-eff/handlers ([raise #:forward]
                      [log (λ ([resume : (-> Void Void)]
                               [v : String])
                             (printf "log(h): ~a~n" v)
                             (resume (void)))])
    (g)))

(module+ main
  (with-eff/handlers ([log (λ ([resume : (-> Void Void)]
                               [v : String])
                             (printf "log: ~a~n" v)
                             (resume (void)))])
    (f "msg"))

  (with-eff/handlers ([raise (λ ([resume : (-> Void Void)]
                                 [err : String])
                               (printf "got error: ~a~n" err))])
    (h))
  )
