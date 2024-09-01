#lang scribble/manual
@require[]

@title[#:tag "limitation"]{Limitation}

To generate proper `call/prompt` and `abort/cc`, every effect handler can only take one input type, so if you want to transfer several arguments, use structure to wrap them.
