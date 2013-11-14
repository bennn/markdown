#lang at-exp racket

;; Try parsing "random" text to see if parser fails. Why? Every input
;; should parse successfully, even if it parses to itself as plain
;; text. There's really no such thing as a syntax error with markdown
;; -- just plain text that didn't turn out to be markdown.
;;
;; This is unlike randomized redex testing, which tries to produce
;; examples of _valid_ markdown that the parser misunderstands. By
;; contrast, this random testing tries to produce examples of
;; _invalid_ markdown that the parser should parse to plain text
;; rather than terminwate with a syntax error.
;;
;; Furthermore, we also want to check for the more fundamental bug of
;; the parser "never" terminating, or at least taking so longer that
;; it's worth investigating if the grammar is wrong.

;; Slow. Put in `test-slow` submodule not `test.
;; Run using `raco test -s test-slow random-test.rkt
(module test-slow racket
  (require "main.rkt")

  ;; In a previous version of this I used completely random
  ;; characters. However we're much more likely to generate something
  ;; that could break the parser if we randomly choose among "tokens"
  ;; that mean something special in markdown (as well as from plain
  ;; words). This results in something that looks like it could be
  ;; markdown -- both to a human and a parser.
  (define tokens
    #("\n" "\n\n" "\n\n\n"
      " " "  " "   " "    "
      "_" "__" "___"
      "*" "**" "***"
      "`" "``" "```"
      "[" "]" "(" ")"
      "&"
      "<" ">"
      "'" "\""
      "<div>" "</div>"
      "<br />"
      "lorem" "ipsum"
      "lorem" "ipsum"
      "lorem" "ipsum"))
  (define (random-token)
    (vector-ref tokens (random (vector-length tokens))))

  (define (random-doc tokens)
    (for/fold ([s ""])
              ([_ (in-range tokens)])
      (string-append s (random-token))))

  (define (check-doc doc)
    (for ([i 3]) (collect-garbage)) ;; since we're timing below
    (define worker
      (thread
       (thunk
        (with-handlers ([exn:fail?
                         (lambda (x)
                           (newline)
                           (displayln (exn-message x))
                           (displayln "For source text:")
                           (displayln doc))])
          ;; suppress "unresolved reference" messages
          (parameterize ([current-error-port (open-output-nowhere)])
            (void (parse-markdown doc)))))))
    (define watcher
      (thread
       (thunk (sleep 30)
              (when (thread-running? worker)
                (newline)
                (displayln "Parser took > 30 sec on source text:")
                (displayln doc)
                (kill-thread worker)))))
    (sync worker watcher))

  (define (random-test reps tokens)
    (display @~a{Trying @reps docs with @|tokens| "tokens" each: })
    (flush-output)
    (for ([i reps])
      (display @~a{@(add1 i) })
      (flush-output)
      (check-doc (random-doc tokens)))
    (newline))

  (random-test 500 300)
  ;; (random-test 1 300)
  ;; (provide (all-defined-out))
  )

;; (require 'test-slow)