#lang racket
(require racket/control
         "with.rkt")

(module+ main
  (define (consume str args)
    (match args
      [(cons head tail)
       #:when (string=? str head)
       (values tail #t)]
      [_  (values args #f)]))

  (define verbose-flag (make-continuation-prompt-tag))
  (define ((verbose-flag-handler box) resume args)
    (let-values ([(args matched?) (consume "--verbose" args)])
      (if matched?
          (begin
            (set-box! box #t)
            (resume args))
          (resume #f))))

  (define arg (make-continuation-prompt-tag))
  (define ((arg-handler box) resume args)
    (match args
      [(cons v args)
       #:when (not (string-prefix? v "-"))
       (set-box! box v)
       (resume args)]
      [_ (resume #f)]))

  (define build-cmd (make-continuation-prompt-tag 'build))
  (define (build-cmd-handler resume args)
    (let-values ([(args matched?) (consume "build" args)])
      (unless matched?
        (resume))
      (let ([verbose (box #f)]
            [project (box #f)])
        (with
         [verbose-flag (verbose-flag-handler verbose)]
         [arg (arg-handler project)]
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
  (define (version-cmd-handler resume args)
    (let-values ([(args matched?) (consume "version" args)])
      (unless matched?
        (resume))
      (printf "example v0.1.0~n")))

  (define (program args)
    (define cmds (list build-cmd
                       version-cmd))
    (for ([c cmds])
      (call/cc (λ (k)
                 (abort/cc c k args)))))


  (with [build-cmd build-cmd-handler]
        [version-cmd version-cmd-handler]
        (program '("build" "hello")))
  (with [build-cmd build-cmd-handler]
        [version-cmd version-cmd-handler]
        (program '("build" "hello" "--verbose")))

  (with [build-cmd build-cmd-handler]
        [version-cmd version-cmd-handler]
        (program '("version"))))
