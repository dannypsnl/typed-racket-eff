#lang scribble/manual
@require[@for-label[typed-racket-eff
                    typed/racket/base]]

@title[#:tag "limitation"]{Limitation}

To generate proper @code{call/prompt} and @code{abort/cc}, every effect handler can only take one input type, so if you want to transfer several arguments, use structure to wrap them.
