#lang typed/racket
(provide with-eff/handlers)
(require "arrow-ty.rkt"
         (for-syntax syntax/parse
                     syntax/stx
                     racket/syntax
                     racket/match))
(require typed/racket/unsafe)
(unsafe-require/typed racket/control
                      [call/prompt
                       (All (TagTy ResumeTy InTy Out)
                            (-> (-> Out)
                                TagTy
                                (-> ResumeTy InTy Out)
                                Out))]
                      [abort/cc
                       (All (TagTy ResumeTy InTy OutTy)
                            (-> TagTy
                                ResumeTy
                                InTy
                                OutTy))])

(define-syntax with-eff/handlers
  (syntax-parser
    [(_ ([tag:id handler] ...) body:expr)
     (define (go rename-eff wrappers l)
       (match l
         [(cons h tail)
          (syntax-parse h
            [(tag #:forward)
             (define forward (generate-temporary #'forward))
             (define t (eval #'tag))
             (go (cons #`(#,forward tag) rename-eff)
                 (cons #`(define/public (tag [x : #,(in-type t)]) : #,(out-type t)
                           (#,forward x))
                       wrappers)
                 tail)]
            [(tag handler)
             (define eff (generate-temporary #'tag))
             (define t (eval #'tag))
             #`({inst call/prompt #,(tag-type t) #,(resume-type t) #,(in-type t)}
                (λ ()
                  #,(go
                     (cons #`(#,eff tag) rename-eff)
                     (cons #`(define/public (tag [x : #,(in-type t)]) : #,(out-type t)
                               (call/cc
                                (λ ([k : #,(resume-type t)])
                                  ({inst abort/cc #,(tag-type t) #,(resume-type t) #,(in-type t) #,(out-type t)}
                                   #,eff k x))))
                           wrappers)
                     tail))
                tag
                handler)])]
         [_ #`(let* (#,@rename-eff
                     [class% (class object%
                               (super-new)
                               #,@wrappers)])
                (body (new class%)))]))

     (go '() '() (syntax->list #'([tag handler] ...)))]))
