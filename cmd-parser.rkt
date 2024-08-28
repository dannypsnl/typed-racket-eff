#lang racket
(require racket/control
         "with.rkt")

(module+ main
  (define (consume str args)
    (match args
      [(cons head tail) #:when (string=? str head)
                        (values #t tail)]
      [_  (values #f args)]))

  (define build-cmd (make-continuation-prompt-tag 'build))
  (define (build-cmd-handler resume args)
    (let-values ([(matched? args) (consume "build" args)])
      (if matched?
          (match args
            [(cons project args)
             (printf "build project: ~a~n" project)]
            [_ (println "expected a input <project>")])
          (resume))))

  (define version-cmd (make-continuation-prompt-tag 'version))
  (define (version-cmd-handler resume args)
    (define-values (matched? rest) (consume "version" args))
    (if matched?
        (printf "example v0.1.0~n")
        (resume)))

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
        (program '("version"))))
