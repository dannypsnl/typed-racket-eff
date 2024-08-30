#lang typed/racket
(provide with-eff/handlers
         forward)
(require "arrow-ty.rkt"
         (for-syntax syntax/parse
                     syntax/stx
                     racket/syntax
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
        (~optional (~seq #:forward {eff*:id ...}))
        body:expr)
     (define forward-bind* #f)
     (define forward-method* #f)
     (when (attribute eff*)
       (let* ([effs (syntax->list #'(eff* ...))]
              [t* (map eval effs)]
              [f* (map (λ (_) (generate-temporary #'forward)) effs)])
         (set! forward-bind* (map (λ (f e) #`(#,f #,e)) f* effs))
         (set! forward-method*
               (map (λ (eff t forward)
                      #`(define/public (#,eff [x : #,(in-type t)]) : #,(out-type t)
                          (#,forward x)))
                    effs
                    t*
                    f*))))

     (define (go rename-eff wrappers l)
       (match l
         [(cons h tail)
          (syntax-parse h
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
                                  ({inst abort/cc #,(tag-type t) #,(resume-type t) #,(in-type t)}
                                   #,eff k x))))
                           wrappers)
                     tail))
                tag
                handler)])]
         [_ (if forward-bind*
                #`(let* (#,@forward-bind*
                         #,@rename-eff
                         [class% (class object%
                                   (super-new)
                                   #,@forward-method*
                                   #,@wrappers)])
                    (body (new class%)))
                #`(let* (#,@rename-eff
                         [class% (class object%
                                   (super-new)
                                   #,@wrappers)])
                    (body (new class%))))]))

     (go '() '() (syntax->list #'([tag handler] ...)))]))

(define-syntax forward
  (syntax-parser
    [(_ (eff* ...) body:expr)
     #'(with-eff/handlers ([eff* eff*] ...) body)]))
