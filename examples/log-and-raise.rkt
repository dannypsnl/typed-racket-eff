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
  (cast
   (with-eff/handlers ([raise #:forward]
                       [log (λ ([resume : (-> Void Void)]
                                [v : String]) : Void
                              (printf "log(h): ~a~n" v)
                              (resume (void)))])
     (g))
   Void))

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
