(define-module (advent-of-code 2020 src expense-report entries)
  (#:use-module srfi srfi-1))

(define (entries-with-sum sum entries)
  (sort entries <))

(take-while (lambda (n) (< n 5)) '(1 2 2 2 3 3 4 5 6 7 7))

