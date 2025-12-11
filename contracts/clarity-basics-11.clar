;; clarity-basics-ii

;; day 8 -  Optionals & Parameters
(define-read-only (show-some)
    (some u2)
)
(define-read-only (show-none)
    none
)
(define-read-only (params (num uint) (string (string-ascii 48)) (boolean bool))
    num
)
(define-read-only (params-optionals (num (optional uint)) (string (optional (string-ascii 48))) (boolean (optional bool)))
    num
)

;; day 9 - Optionals pt. 2
(define-read-only (is-some-examples (num (optional uint)))
    (is-some num)
)
(define-read-only (is-none-examples (num (optional uint)))
    (is-none num)
)
(define-read-only (params-optionals-and (num (optional uint)) (string (optional (string-ascii 48))) (boolean (optional bool)))
    (and
        (is-some num)
        (is-some string)
        (is-some boolean)
    )
)

;; day 10 - constants & introduction to variables
(define-constant fav-num u10)
(define-constant fav-string "hi")
(define-data-var fav-num-var uint u11)
(define-data-var your-name (string-ascii 24) " Rogersterkaa")

(define-read-only (show-constant)
    fav-num
)
(define-read-only (show-constant-double)
    (* fav-num u2)
)
(define-read-only (show-fav-num-var)
    (var-get fav-num-var)
)
(define-read-only (show-var-double)
    (* u2 (var-get fav-num-var))
)
(define-read-only (say-hi)
    (concat fav-string (var-get your-name))
)

;; day 11 - public functions & responses
;; a response as the name suggest is a response to any function that create change or writes to the contract
;; just like optionals, responses wrap values but they are not exactly the same
;; whenever you want to write or update a contract, to check at the end that everything went ok you will need to use the data type called response
;; the response data type has two values; it either returns with "ok" or "error" message
;; responses are very important, they are used when you are writing or updating a contract at the last line
;; define-public are used when you are writing or changing anything on a contract, they are required to have a response as a final value in the line of logic 
(define-read-only (response-example)
    (ok u10)
)
(define-public (change-name (new-name (string-ascii 24)))
    (ok (var-set your-name new-name))
)
(define-public (change-fav-num (new-num uint))
    (ok (var-set fav-num-var new-num))
)

;; day 12 - Tuples & merging
;; a tuple is a data type that lives within two brackets that has multiple key and values seperated by a coma
;; tuples once created are fixed and imutable, however using merge you can merge another tuple into an existing tuple to create a new tuple with updated values
;; The second tuple overrides the first tuple
(define-read-only (read-tuple-1)

    {
        user-principal: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM,
        user-name: "rogersterkaa", 
        user-balnce: u10
    }
)
(define-public (write-tuple-1 (new-user-principal principal) (new-user-name (string-ascii 24)) (new-user-balance uint)) 
   (ok {
        user-principal: new-user-principal,
        user-name: new-user-name, 
        user-balance: new-user-balance
    }) 
)
(define-data-var original {user-principal: principal, user-name: (string-ascii 24), user-balnce: uint}
    {
        user-principal: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM,
        user-name: "rogersterkaa", 
        user-balnce: u10
    }
)
(define-read-only (read-original)
    (var-get original)
)
(define-public (merge-principal (new-user-principal principal))
    (ok (merge
        (var-get original)
        {user-principal:new-user-principal}
    ))
)
(define-public (merge-user-name (new-user-name (string-ascii 24)))
    (ok (merge
        (var-get original)
        {user-name:new-user-name}
    ))   
)
(define-public (merge-all (new-user-principal principal) (new-user-name (string-ascii 24)) (new-user-balance uint)) 
    (ok (merge
        (var-get original)
        {
            user-principal: new-user-principal,
            user-name: new-user-name, 
            user-balance: new-user-balance
      }
    ))   
)



;; day 13 - Tx-sender Is & Eq
;; Tx-sender refers to the person that signed the transaction. whoever clicked the button to submit transaction.
;; Another built in conditional use to compare that two values are the same is "Is-Eq"
(define-read-only (show-tx-sender)
    tx-sender
)
(define-constant admin 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
(define-read-only (check-admin)
    (is-eq admin  tx-sender)
)

;; day 14 - conditionals : (Asserts)
(define-read-only (assert-example (num uint))
    (ok (asserts! (> num u2) (err u1)))
)
(define-constant err-too-large (err u1))
(define-constant err-too-small (err u2))
(define-constant err-not-auth (err u3))
(define-constant admin-one tx-sender)

(define-read-only (assert-admin)
    (ok (asserts! (is-eq tx-sender admin-one) err-not-auth))
)

;; day 15 - Begin
;; se & say hello
;; counter by even
;; Begin allows us to declare to clarity we are about to write an extended function with multiple lines of logic in it

(define-data-var hello-name (string-ascii 48) "Alice")
;; @desc -  this function allows a user to provide a name, which, if different, changes a name variable & returns 'hello new name'
;; @param new-name: (string-ascii 48) that represent the new name
(define-public (set-and-say-hello-name (new-name (string-ascii 48)))
    (begin
        ;; assert that name is not empty
        (asserts! (not (is-eq "" new-name)) (err u1))

        ;; assert that name is not equal to current name
        (asserts! (not (is-eq (var-get hello-name) new-name)) (err u2))

        ;; var-set new name
        (var-set hello-name new-name)

        ;; say hello new name
        (ok (concat "Hello " (var-get hello-name)))
    )
)
(define-read-only (read-hello-name)
    (var-get hello-name)
)

(define-data-var counter uint u0)
(define-read-only (read-counter)
    (var-get counter)
)

;; @desc - this function allows a user to increase the counter by only an even amount
;; @param - add-num: uint that user sumit to add to counter
(define-public (increment-counter-even (add-num uint))
    (begin
        ;; Assert that add-num is even
        (asserts! (is-eq u0 (mod add-num u2)) (err u3))

        ;; increment & var-get counter
        (ok (var-set counter (+ (var-get counter) add-num)))
    )
)