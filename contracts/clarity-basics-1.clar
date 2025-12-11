;; clarity-basics-1.clar
;; day 3 - booleans & read-only functions
;; day 4 - uints, ints, & simple operators
;; here we are to review the very basics of clarity

(define-read-only (show-true-i)
    true
)
(define-read-only (show-false-i)
    false
)
(define-read-only (show-true-ii)
    (not false)
)
(define-read-only (show-false-ii)
    (not true)
)

;; day 4
(define-read-only (add)
    (+ u1 u1)
)
(define-read-only (subtract)
    (- 1 2)
)
(define-read-only (multiply)
    (* u2 u3)
)
(define-read-only (divide)
    (/ u6 u2)
)
(define-read-only (uint-to-int)
    (to-int u4)
)
(define-read-only (int-to-uint) 
    (to-uint -2)
)

;; day 5 - advance operators
(define-read-only (exponent)
    (pow u2 u3)
)
(define-read-only (square-root)
    (sqrti u25)
)
(define-read-only (modulo)
    (mod u4 u2)
)
(define-read-only (log-two)
    (log2 u16)
)

;; day 6 - Strings
(define-read-only (say-hello)
    "hello"
)
(define-read-only (say-hello-world)
    (concat "hello" "world")
)
(define-read-only (say-hello-world-name)
    (concat 
        (concat "hello" "world,") 
        "rogersterkaa"
    )
)

;; day 7 - And/Or
(define-read-only (and-i)
    (and true true)
)
(define-read-only (and-ii)
    (and true false)
)
(define-read-only (and-iii)
    (and 
        (> u2 u1) 
        (not false) 
         true
    )
)
(define-read-only (or-i)
    (or true false)
)
(define-read-only (or-ii)
    (or (not true) false)
)
(define-read-only (or-iii)
    (or 
       (< u2 u1) 
       (not true) 
       (and (< u2 u1) true)
    )
)

