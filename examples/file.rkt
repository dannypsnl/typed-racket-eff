#lang typed/racket
(require typed-racket-eff)

(effect fread : (-> Void String))

(define/eff (f) : Void { fread }
  (println (fread (void))))

(define in (open-input-file "file.rkt"))
(with-eff/handlers ([fread (λ ([resume : (-> String Void)]
                               [_ : Void])
                             (read-line in))])
  #:finally (λ () (close-input-port in))
  (f))
