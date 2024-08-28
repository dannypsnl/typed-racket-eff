#lang racket
(require racket/control
         "with.rkt")

(define (consume str args)
  (match args
    [(cons head tail)
     #:when (string=? str head)
     (values tail #t)]
    [_  (values args #f)]))

(define verbose-flag (make-continuation-prompt-tag))
(define ((handle-flag box flag . variant-flags) resume args)
  (for ([f (cons flag variant-flags)])
    (let-values ([(args matched?) (consume f args)])
      (if matched?
          (begin
            (set-box! box #t)
            (resume args))
          (void))))
  (resume #f))

(define arg (make-continuation-prompt-tag))
(define ((handle-arg box) resume args)
  (match args
    [(cons v args)
     #:when (not (string-prefix? v "-"))
     (set-box! box v)
     (resume args)]
    [_ (resume #f)]))

(define build-cmd (make-continuation-prompt-tag 'build))
(define (handle-build-cmd resume args)
  (let-values ([(args matched?) (consume "build" args)])
    (unless matched?
      (resume))
    (let ([verbose (box #f)]
          [project (box #f)])
      (with
       [verbose-flag (handle-flag verbose "--verbose" "-V")]
       [arg (handle-arg project)]
       (begin
         (let loop ([args args])
           (unless (empty? args)
             (for ([a (list verbose-flag arg)])
               (match (call/cc (λ (k) (abort/cc a k args)))
                 [#f (void)]
                 [args (loop args)]))))
         (when (unbox verbose)
           (printf "verbose mode~n"))
         (printf "build project ~a~n" (unbox project)))))))

(define version-cmd (make-continuation-prompt-tag 'version))
(define (handle-version-cmd resume args)
  (let-values ([(_args matched?) (consume "version" args)])
    (unless matched?
      (resume))
    (printf "example v0.1.0~n")))

(define (program args)
  (define cmds (list build-cmd
                     version-cmd))
  (for ([c cmds])
    (call/cc (λ (k)
               (abort/cc c k args)))))

(module+ main
  (with [build-cmd handle-build-cmd]
        [version-cmd handle-version-cmd]
        (program '("build" "hello")))
  (with [build-cmd handle-build-cmd]
        [version-cmd handle-version-cmd]
        (program '("build" "hello" "--verbose")))
  (with [build-cmd handle-build-cmd]
        [version-cmd handle-version-cmd]
        (program '("build" "hello" "-V")))

  (with [build-cmd handle-build-cmd]
        [version-cmd handle-version-cmd]
        (program '("version"))))

(module+ test
  )
