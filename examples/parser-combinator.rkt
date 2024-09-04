#lang typed/racket
(require "../main.rkt")

(effect raise : (-> String Void))
(effect peek : (-> Integer (U Char EOF)))
(effect next : (-> Void (U Char EOF)))

(define/eff (digit) : Char { peek next raise }
  (define c (peek 0))
  (if (match c
        [#\1 #t]
        [#\2 #t]
        [#\3 #t]
        [#\4 #t]
        [#\5 #t]
        [#\6 #t]
        [#\7 #t]
        [#\8 #t]
        [#\9 #t]
        [#\0 #t]
        [_ #f])
      (cast (next (void)) Char)
      (begin (raise "not digit")
             #\0)))

(define/eff (many [f : (-> (Eff Char (effs peek next raise)))]) : String { peek next }
  (let/cc return : String
    (let loop : String ([init : (Listof Char) '()])
      (loop
       (cons
        (cast (with-eff/handlers ([peek #:forward]
                                  [next #:forward]
                                  [raise (λ (_resume err)
                                           (return (list->string (reverse init))))])
                (f))
              Char)
        init)))))

(define in (open-input-string "111 + 2 + 3"))
(with-eff/handlers ([peek (λ (resume skip)
                            (resume (peek-char in skip)))]
                    [next (λ (resume _)
                            (resume (read-char in)))]
                    [raise (λ (_resume err)
                             (printf "Failed ~a~n" err))])
  (many digit))
