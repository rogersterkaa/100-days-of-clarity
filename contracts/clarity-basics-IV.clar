;; title: clarity-basics-IV
;; Reviewing more clarity fundamentals
;; Written by Rogersterkaa
;; Day 26.5 - Let
;; Let let you to create local variables within the scope of a function
;; While Begin allows us to declare to clarity we are about to write an extended function with multiple lines
(define-data-var counter uint u0)
(define-map counter-history uint { user: principal, count: uint })

;; (begin
;;      body (function 1)
;;      (function 2)
;;  )

;; (let
;;  (
;;      ;;local vars are created/stored
;;      (test-var u0)
;;  )
;;       body (function 1)
;;       (function 2)
;;  )

(define-public (increase-count-begin (increase-by uint))
    (begin
         
        ;; assert that tx-sender is not previous counter-history user
        (asserts! (not (is-eq (some tx-sender) (get user (map-get? counter-history (var-get counter))))) (err u0))

         ;; var-get counter-history
         (map-set counter-history (var-get counter) {
            user: tx-sender,
            count: (+ increase-by (get count (unwrap! (map-get? counter-history (var-get counter)) (err u1))))
         })

        ;; var-set increase counter
        (ok (var-set counter (+ (var-get counter) u1)))
        
    )
)


(define-public (increase-count-let (increase-by uint)) 
    (let
        (
            ;; local var
            (current-counter (var-get counter))
            (current-counter-history (default-to {user: tx-sender, count: u0} (map-get? counter-history current-counter)))
            (previous-counter-user (get user current-counter-history))
            (previous-count-amount (get count current-counter-history))
        )
            ;; assert that tx-sender is "not" previous counter-history user
            (asserts! (not (is-eq tx-sender previous-counter-user)) (err u0))
            
            ;; var-set counter-history
            (map-set counter-history current-counter {
                user: tx-sender,
                count: (+ previous-count-amount)
            })
            ;; var-set increase counter
            (ok (var-set counter (+ u1 current-counter)))
    )
)



;; Day 32 - Syntax
;; there are two different forms of syntax in clarity that you will see through your clarity journey
;; 1. Trailing (heavy parenthesis that trail)
;; 2. Encapsulated (highlights inteenal function)
(define-public (increase-count-trailing (increase-by uint)) 
    
    (begin 
          ;; assert that tx-sender is not previous counter history user
          (asserts! 
              (not (is-eq 
                  (some tx-sender) (get user (map-get? counter-history (var-get counter))))) (err u0))
         
        (ok 
            (var-set counter
                (+ (var-get counter) u1)))  
    )
)

(define-public (increase-count-encapsulation (increase-by uint)) 
    
    (begin 
          ;; assert that tx-sender is not previous counter history user
        (asserts! 
            (not 
                (is-eq 
                    (some tx-sender) 
                    (get 
                        user 
                        (map-get? counter-history (var-get counter))
    
                    )     
                )
            )
            (err u0)
        )




        (ok
            (var-set counter
                (+ 
                    (var-get counter) 
                    u1  
                )
            )
        ) 
    )
)  

;; Day 33 -Stx transfers
(define-public (send-stx-single) 
    (ok (stx-transfer? u1000000 tx-sender 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG))
)

(define-public (send-stx-double)
    (begin
        (unwrap! (stx-transfer? u1000000 tx-sender 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG) (err u0))
        (stx-transfer? u1000000 tx-sender 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
    
    )
)

;; Day 34 - Stx-get-balance & Stx-burn
;; Stx-balance
;; Stx-burn
(define-read-only (balance-of)
    (stx-get-balance  tx-sender)
)

(define-public (send-stx-balance) 
    (ok (stx-transfer? (stx-get-balance tx-sender) tx-sender 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG))
)

;; burning in Stx means destroying an asset or decrease in the total supply. it goes to no wallet, it is forever gone
(define-public (burn-some (amount uint))
    (stx-burn? amount tx-sender)
)
(define-public (burn-half-of-balance)
    (stx-burn? (/ (stx-get-balance tx-sender) u2) tx-sender)
)

;; Day 35 - Block-height
;; Block-height is used  to determine the height of the blocks in the blockchain, used to creat time locks or delays in clarity contracts

(define-read-only (read-current-height)
    stacks-block-height
)
(define-constant day-in-blocks u144)
(define-read-only (has-a-day-passed)
    (if (> stacks-block-height day-in-blocks)
        true
        false
    )
)
(define-read-only (has-a-week-passed)
   (if (> stacks-block-height (+ day-in-blocks u7))
        true
        false
    )
)  

;; Day 36 - As-Contract
;; As-cotract allows us to execute functions as the contract
;; when we use Tx-sender it is always the person that sign the contract, but when we wrap tx-sender with as-contract, it changes the context in terms of who is executing what
;; wwhenever we use as-contract, it si typically because we want to change the contract to send or receive something
;; principal -> cotract
(define-public (send-to-contract-literal)
    (stx-transfer? u1000000 tx-sender 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.clarity-basics-IV)
)
(define-public (send-contract-context)
    (stx-transfer? u1000000 tx-sender (as-contract tx-sender))
)
;; contract -> principal
(define-public (send-as-contract)
    (as-contract (stx-transfer? u1000000 tx-sender 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM))
)
(define-public (send-as-contract-11)
    (stx-transfer? u1000000 (as-contract tx-sender) tx-sender)
)