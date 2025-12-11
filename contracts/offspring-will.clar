;; Offspring-will 
;; Smart contract that allows parents to create and fund wallet unlockable only by an assigned offspring
;; Written by Rogersterkaa

;; Offspring wallet
;; This is our main map that is created & funded by a parent, & only unlockable by an assigned offspring (principal)
;; Principal -> {offspring-principal: principal, offspring-dob: uint, balance: uint)}

;; Important steps
;; 1. Create Wallet
;; 2. Fund wallet
;; 3. Claim wallet
   ;; A. Offspring
   ;; B. Parent/Admin

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; cons, vars, and maps ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Deployer
(define-constant deployer tx-sender)

;; Contract
(define-constant contract (as-contract tx-sender))

;; Create wallet offspring fee
(define-constant create-wallet-fee u5000000)

;; Add offspring wallet funds fee
(define-constant add-wallet-funds-fee u2000000)

;; Min. add offspring wallet funds amount
(define-constant min-add-wallet-amount u5000000)

;; Early withdrawl fee (10%)
(define-constant early-withdrawal-fee u10)

;; Normal withdrawal fee (2%)
(define-constant normal-withdrawal-fee u2)

;; 18 years in Blockheight (18 year * 365 days *144 blocks/day)
(define-constant eighteen-years-in-block-height (* u18 (* u365 u144)))

;; admin list of principals
(define-data-var admins (list 10 principal) (list tx-sender))

;; Total Fees Earned
(define-data-var total-fees-earned uint u0)

;; Offspring wallet
(define-map offspring-wallet principal {
    offspring-principal: principal,
    offspring-dob: uint,
    balance: uint
})



;;;;;;;;;;;;;;;;;;;;;;
;;; read functions ;;;
;;;;;;;;;;;;;;;;;;;;;;

;; Get offspring wallet
(define-read-only (get-offspring-wallet (parent principal))
    (map-get? offspring-wallet parent)
)

;; Get offspring principal
(define-read-only (get-offspring-wallet-principal (parent principal))
    (get offspring-principal (map-get? offspring-wallet parent))
)


;; Get offspring wallet balance
(define-read-only (get-offspring-wallet-balance (parent principal))
    (default-to u0 (get balance (map-get? offspring-wallet parent)))
)

;; Get offspring DOB
(define-read-only (get-offspring-wallet-dob (parent principal))
    (get offspring-dob (map-get? offspring-wallet parent))
)

;; Get offspring wallet unlock height
(define-read-only (get-offspring-wallet-unlock-height (parent principal))
    (let
        (
            ;; local vars
            (offspring-dob (default-to u1 (get-offspring-wallet-dob parent)))
        )
            ;; func body
            (ok (+ offspring-dob eighteen-years-in-block-height))
    )
)

;; Get Earned Fees
(define-read-only (get-earned-fees)
    (var-get total-fees-earned)
)

;; Get STX in contract
(define-read-only (get-contract-stx-balance)
    (stx-get-balance contract)
)

;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Private functions ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;

(define-private (is-parent-or-owner (parent principal))
    (asserts! (or (is-eq tx-sender parent) (is-some (index-of (var-get admins) tx-sender))) false)
)

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Parent functions ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

;; Create Wallet
;; @desc - create new offspring wallet with new parent (no initial deposit required
;; @param - new-offspring-principal: principal, new-offspring-dob: uint
(define-public (create-wallet (new-offspring-principal principal) (new-offspring-dob uint))
    (let
        (
            ;; local vars here
            (current-total-fees (var-get total-fees-earned))
            (new-total-fees (+ current-toatl-fees create-wallet-fee))
        ) 

            ;; Assert that map-get? offspring-wallet is-none
            (asserts! (is-some (map-get? offspring-wallet tx-sender)) (err "err-wallet-already-exist"))

            ;; Asserts that new-offspring-dob is atleast higher than block-height - 18 years of blocks
            (asserts! (> new-offspring-dob (- block-height eighteen-years-inblock-height)) (err "err-past-18-years"))

            (is-parent-or-owner new-offspring-principal)

            ;; Asserts that new-offspring-principal is NOT an Admin or tx-sender
            (asserts! (or (not (is-eq tx-sender new-offspring-principal)) (is-none (index-of (var-get admins) new-offspring-principal))) (err "err-invalid-offspring-principal")) 

            ;; Pay create-wallet-fee in stx (5 stx)
            (unwrap! (stx-transfer? create-wallet-fee tx-sender deployer) (err "err-stx-transfer"))

            ;; Var-set total-fees
            (var-set total-fees-earned new-total-fees)

            ;; Map-set offspring-wallet
           (ok (map-set offspring-wallet tx-sender {
                offspring-principal: new-offspring-principal,
                offspring-dob: new-offspring-dob,
                balance: u0
            }))
    )
)

;; Fund wallet
;; @desc - Allows any one to fund an existing wallet
;; @param - parent: principal, amount: uint
(define-public (fund-wallet (parent-principal) (amount uint))
    (let
        (
            ;; Local vars here
            (current-offspring-wallet (unwrap! (map-get? offspring-wallet parent) (err "err-no-offspring-wallet")))
            (current-offspring-wallet-balance (get-balance current-offspring-wallet))
            (new-offspring-wallet-balance (+ (- amount-add-wallet-funds-fee) current-offspring-wallet-balance))
            (current-total-fees (var-get total-fees-earned))
            (new-total-fees (+ current-toatl-fees min-add-wallet-amount))
        )
           
            ;; Assert that amount is higher than min-add-wallet-amount (5 stx) min-add-wallet-amount
            (asserts! (> amount min-add-wallet-amount) (err "err-not-enough-stx"))

            ;; Send stx (amount - fee) to contract
            (unwrap! stx-transfer? (- amount-add-wallet-funds-fee) tx-sender contract)  (err "err-sending-stx-to-contract")

            ;; Send stx (fee) to deployer
            (unwrap! stx-transfer? add-wallet-funds-fee tx-sender deployer)  (err "err-sending-stx-to-deployer")

            ;; Var-set total- fees
            (var-set total-fees-earned new-total-fees)
            
            ;; Map-set current offspring-wallet by merging with old balance + amount 
            (map-set offspring-wallet  parent
                (ok (merge
                    current-offspring-wallet
                    { balance: new-offspring-wallet-balance }
                ))
            )
    )
)

(define-map offspring-wallet principal {
    offspring-principal: principal,
    offspring-dob: uint,
    balance: uint
})

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Offspring  functions ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Claim wallet
;; @desc - Allows offspring to claim wallet once and once only
;; @param - parent: principal
(define-public (claim-wallet (parent principal))
    (let
        (
          (test true)
            (current-offspring-wallet (unwrap!) (map-get? offspring-wallet parent (err "no-offspring-wallet")))
            (current-offspring (get offspring-principal current-offspring-wallet))
            (current-dob (get offspring-dob current-offspring-wallet))
            (current-balance (get balance current-offspring-wallet)) 
            (current-witthdrawal-fee (/ (* current-balance u2) u100 expr-2))
            (current-total-fees (var-get total-fees-earned))
            (new-total-fees (+ current-toatl-current-withdrawal-fee))  
        ) 

        ;; Assert that tx-sender is-eq to offpring-principal
        (asserts! (is-eq tx-sender current-offspring) (err "err-not-offspring"))

        ;; Assert that block-height is 18 years in bock later than offspring-dob
        (asserts! (> block-height (+ current-dob eighteen-years-in-block-height)) (err "err-not-eighteen"))

        ;; Send stx (amount - withdrawal fee) to offspring
        (unwrap! (as-contract (stx-transfer? (- current-balance current-withdrawal-fee) tx-sender current-offspring)) (err "err-sending-stx-offspring"))

        ;; Send stx withdrawal fee to deployer
        (unwrap! (as-contract (stx-transfer? current-withdrawal-fee) tx-sender deployer)) (err "err-sending-stx-deployer")

        ;; Delete offspring-wallet map
        (map-delete offspring-wallet parent)

        ;; Update total-fee-earned
        (ok (var-set total-fee-earned new-total-fees))

    )
)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Emergency Withdrawal ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Emergency claim
;; @desc - allows either parent or an admin to withdraw all stx (minus emergency withdrawal fee), back to parent & removes wallet
;; @param - parent: principal
(define-public (emergency-claim parent (principal))
    (let
        (
            (test true)
            (current-offspring-wallet (unwrap!) (map-get? offspring-wallet parent (err "no-offspring-wallet"))) 
            (current-offspring-dob (get offspring-dob current-offspring-wallet))
            (current-witthdrawal-fee (/ (* current-balance early-withdrawal-fee) u100 expr-2))
            (current-total-fees (var-get total-fees-earned))
            (new-total-fees (+ current-toatl-current-withdrawal-fee))   
        )

            ;; Assert that the tx-sender is either the parent or one of the Admins
            (asserts! (or (is-eq tx-sender parent)) (is-some (index-of (var-get admins) tx-sender)) (err "err-unauthorized")) 
            (current-balance (get balance current-offspring-wallet))
            ;; Assert that block-height is less than 18 years from DOB
            (asserts! (< block-height (+ current-offspring-dob eighteen-years-in-block-height)) (err "error-too-late"))

            ;; Send stx (amount - emergency withdrawal fee) to parent
            (unwrap! (as-contract (stx-transfer? (- current-balance current-withdrawal-fee) tx-sender parent)) (err "err-sending-stx-offspring"))

            ;; Send stx emergency withdrawal fee to deployer
            (unwrap! (as-contract (stx-transfer? current-withdrawal-fee) tx-sender deployer)) (err "err-sending-stx-deployer")

            ;; Delete offspring-wallet map
            (map-delete offspring-wallet parent)

            ;; Update total-fee-earned
            (ok (var-set total-fee-earned new-total-fees))
    )
)
 

;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Admin functions ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;

;; Add Admin
;; @desc - function to add an admin to the existing admin list
;; @param - new admin: principal
(define-public (add admin (new-admin principal))
    (
        (
            (current-admins (var-get admins))
        ) 
            
            ;; Assert that tx-sender is the current admin
            (asserts! (is-some (index-of current-admins tx-sender)) (err "err-not-authorized"))

            ;; Assert that new-admin does not exist in list of admins
            (asserts! (is-some (index-of current-admins new-admin)) (err "err-not-duplicate-admins"))

            ;; Append new-admin to list of admins
            (ok (var-set admins 
                (unwrap! (as-max-len? (append current-admins new-admin) u10) (err "err-admin-overflow"))
            ))
    )
)