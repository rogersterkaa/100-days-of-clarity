;; title: clarity-basics-111
;; here we are dealing with another data type called sequences (list)
;; sequence is used when we want to host multiple values of one data type together
;; sequences equals lists
;; when you work with lists you have to keep the data type the same
;; in clarity because blockchain languages need to be very precise and sizable, lists only have a fix length
(define-read-only (list-bool)
    (list true false true)
)
(define-read-only (list-nums)
    (list u1 u2 u3)
)
(define-read-only (list-strings)
    (list "hello" "world" "terkaa")
)
(define-read-only (list-principal)
   (list tx-sender 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
)
;; remember when you are using a principal you have to put an apostrophe infront of it
(define-data-var num-list (list 10 uint) (list u1 u2 u3 u4))
(define-data-var principal-list (list 5 principal) (list tx-sender 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG))

;; element-at (index -> uint, my-list -> value)
(define-read-only (element-at-num-list (index uint))
    (element-at (var-get num-list) index)
)
(define-read-only (element-at-principal-list (index uint))
    (element-at (var-get principal-list) index)
)
;; Index-of (value -> index)
(define-read-only (index-of-num-list (item uint))
    (index-of (var-get num-list) item)
)
(define-read-only (index-of-principal-list (item principal))
    (index-of (var-get principal-list) item)
)

;; Day 21 List conti.. & intro to unwrapping
(define-data-var list-day-21 (list 5 uint) (list u1 u2 u3 u4))
(define-read-only (list-length)
    (len (var-get list-day-21))
)
(define-public (add-to-list (new-num uint))
    (ok (var-set list-day-21
        (unwrap!
            (as-max-len? (append (var-get list-day-21) new-num) u5) 
        (err u0))
    ))
)

;; Day 22 - Unwrapping conti..

(define-public (unwrap-example (new-num uint))
    (ok (var-set list-day-21
        (unwrap! 
            (as-max-len? (append (var-get list-day-21) new-num) u5) 
        (err u0))
    ))
)
(define-public (unwrap-panic-example (new-num uint))
    (ok (var-set list-day-21
        (unwrap-panic (as-max-len? (append (var-get list-day-21) new-num) u5))
    ))
)
(define-public (unwrap-err-example (input (response uint uint)))
    (ok (unwrap-err! input (err u10)))
)
(define-public (try-example (input (response uint uint)))
(ok (try! input))
)
;; unwrap! -> accept both optionals and response
;; unwrap-err! -> only accept response
;; unwrap-panic -> takes in both optionals and response
;; unwrap-err-panic -> takes in either optionals or response
;; Try! -> also accept both optionals and response

;; Day 23 - Default-to / Get
;; default-to -> used when unwrapping an optional, however instead of throwing an error when the optional is none, it allows you to set a default value
;; get -> used when working with tuples, allows you to get a value from a tuple by providing the key
(define-constant example-tuple {
    example-bool: true,
    example-num: none,
    example-string: none,
    example-principal: tx-sender
})

(define-read-only (read-example-tuple) 
    example-tuple
)
(define-read-only (read-example-bool)
    (get example-bool example-tuple)
) 

(define-read-only (read-examplenum)
    (default-to u10 (get example-num example-tuple))
)

(define-read-only (read-example-string)
    (default-to "rogersterkaa" (get example-string example-tuple))
)

;; Day 24 - Conditionals conti.. - Match & If
;; The three major types of conditionals in Clarity are: if, asserts, and match
;; If -> the universal conditionals, used to execute code based on whether a condition is true or false
;; Asserts -> used when we want fail case either response or optional to exit and revert the transaction chain
;; Match -> used when unwrapping optionals and responses with the intention of storing / using a local variable

(define-read-only (if-example (test-bool bool))
    (if test-bool
        ;; evaluates to true
        "evaluated to true!"
        ;; evaluates to false   
        "evaluates to false!"
    )
)
(define-read-only (if-example-num (num uint))
    (if (and (> num u0 ) (< num u10))
        ;; evaluates to true
        num
        ;; evaluates to false   
        u10
    )
)
;; whenever you want to do a conditional, and it deals with either an optional or a response, it is preferable to use match and especially if you want to serve and use that value later on
;; Match allows you to bind the return values from the conditional

(define-read-only (match-functional-some)
    (match (some u1)
        ;; some value / there was some optional
        match-value (+ u1 match-value)
        ;; none value / there was no optional
        u0
    )   
)
(define-read-only (match-optional (test-value (optional uint)))
    (match test-value
        match-value (+ u2 match-value)
        u0
    )
)
;; you use match specifically when you want to use conditionals with an optional or a responses
;; if you want to use something that fails out and revert automatically use asserts
;; when you want to use a conditional that uses either optionals or responses but you want to continue either on a true or false scenerio use match

(define-read-only (match-response (test-value (response uint uint)))
    (match test-value
        ok-value ok-value
        error-value u0
    )
)

;; Day 25 - Maps
;; Maps, aka hash table, are what we use when we need to associate or tie together any two data types (from one key to one value)
;; 90% of all contracts, you will end up using a map. A map will allow you to associate and keep association between any two data types
(define-map first-map principal (string-ascii 24))
(define-public (set-first-map (username (string-ascii 24)))
    (ok (map-set first-map tx-sender username))
)
(define-read-only (get-first-map (key principal))
    (map-get? first-map key)
)

(define-map second-map principal {
    username: (string-ascii 24),
    balance: uint,
    referral: (optional principal)
})

(define-public (set-second-map (new-username (string-ascii 24)) (new-balance uint) (new-referral (optional principal)))
    (ok (map-set second-map tx-sender {
        username: new-username,
        balance: new-balance,
        referral: new-referral
    }))
)

;; Day 26 - Maps conti..
(define-public (insert-first-map (username (string-ascii 24)))
    (ok (map-insert first-map tx-sender username))
)
;; whenever you want to allow a map value to be written over again and again use map-set 
;; whenever you want to only allow a map value to be written once use map-insert

(define-map third-map {user: principal, cohort: uint } {
    username: (string-ascii 24),
    balance: uint,
    referral: (optional principal)
})
(define-public (set-third-map (cohort-id uint) (new-username (string-ascii 24)) (new-balance uint) (new-referral (optional principal)))
    (ok (map-set third-map { user: tx-sender, cohort: cohort-id } {
        username: new-username,
        balance: new-balance,
        referral: new-referral
    }))
)
(define-public (delete-third-map)
    (ok (map-delete third-map { user: tx-sender, cohort: u1}))
)
(define-read-only (read-third-map) 
    (map-get? third-map { user: tx-sender, cohort: u1})
)