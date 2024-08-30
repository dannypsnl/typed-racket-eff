#lang typed/racket
(provide with-eff/handlers)
(require "arrow-ty.rkt"
         (for-syntax syntax/parse
                     syntax/stx
                     racket/match))
(require typed/racket/unsafe)
(unsafe-require/typed racket/control
                      [call/prompt
                       (All (TagTy ResumeTy InTy)
                            (-> (-> Void)
                                TagTy
                                (-> ResumeTy InTy Void)
                                Void))]
                      [abort/cc
                       (All (TagTy ResumeTy InTy)
                            (-> TagTy
                                ResumeTy
                                InTy
                                Void))])

(define-syntax with-eff/handlers
  (syntax-parser
    [(_ ([tag handler] ...)
        body:expr)
     (define (go wrappers l)
       (match l
         [(cons h tail)
          (syntax-parse h
            [(tag handler)
             (define t (eval #'tag))
             #`({inst call/prompt #,(tag-type t) #,(resume-type t) #,(in-type t)}
                (λ ()
                  #,(go
                     (cons #`(ann (cons 'tag (λ ([x : #,(in-type t)])
                                               (call/cc (λ ([k : #,(resume-type t)])
                                                          ({inst abort/cc #,(tag-type t) #,(resume-type t) #,(in-type t)} tag k x)))))
                                  (Pairof Symbol Procedure))
                           wrappers)
                     tail))
                tag
                handler)])]
         [_ #`(body (make-hash (list #,@wrappers)))]))

     (go '() (syntax->list #'([tag handler] ...)))]))
