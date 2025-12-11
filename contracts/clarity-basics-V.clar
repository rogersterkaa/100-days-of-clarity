;; title: clarity-basics-V
;; Reviewing more clarity fundamentals
;; Written by Rogersterkaa

;; Day 45 - Private Functions
;; private functions can only be called within the contract itself. That means only define-read-only and define-public functions can can call private functions
;; Nothing outside the contract can triger a private function; no wallet, no principal, no other contract can triger a private function
(define-read-only (say-hello-read)
    (say-hello-world)
)

(define-public (say-hello-public)
    (ok (say-hello-world))
)

(define-private (say-hello-world)
    "hello-world"
)

;; Day 46 - Filter (A List Function)
(define-constant test-list (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10))
(define-read-only (test-filter-remove-smaller-than-5)
    (filter filter-smaller-than-5  test-list)
)

(define-read-only (test-filter-remove-odds)
    (filter filter-remove-odds test-list)
)

(define-private (filter-smaller-than-5 (item uint))
    (< item u5)
)

(define-private (filter-remove-odds (item uint))
    (is-eq (mod item u2) u0)
)

;; Day 47 - Map (Another List function)
;; This Map is a function used over a list, it is different from "Maps" as a Data type. Don't confuse the two
;; Whenever you use map the life of the list will always be exactly the same, you use map when you want the life of a list to  remain perfectly unchanged 
;; It is called map because it maps every value to another value
(define-constant test-list-strings (list "Alice" "Bob" "Carl"))

(define-read-only (test-map-increase-by-one)
    (map add-by-one  test-list)
)

(define-read-only (test-map-double)
    (map double  test-list)
)
(define-read-only (test-map-names)
    (map hello-name test-list-strings)
)
 
(define-private (add-by-one (item uint))
    (+ item u1)
)

(define-private (double (item uint))
    (* item u2)
)
(define-private (hello-name (item (string-ascii 24)))
    u0
)

;; Day 48 - Map Revisited
(define-constant test-list-principals (list 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM))
(define-constant test-list-tuple (list {user: "Alice", balance: u10} {user: "Bob", balance: u11} {user: "Carl", balance: u12}))
(define-public (test-send-stx-multiple)
    (ok (map send-stx-multiple test-list-principals))
)
(define-read-only (test-get-users)
    (map get-user test-list-tuple)
)
(define-read-only (test-get-balance)
    (map get-balance test-list-tuple)
)


(define-private (send-stx-multiple (item principal))
    (stx-transfer? u100000000 tx-sender item)
)
(define-private (get-user (item {user: (string-ascii 24), balance: uint}))
    (get user item)
)
(define-private (get-balance (item {user: (string-ascii 24), balance: uint}))
    (get balance item)
)


;; Day 49 - Fold (3rd List Function)
(define-constant test-list-ones (list u1 u1 u1 u1 u1))
(define-constant test-list-two (list u1 u2 u3 u4 u5))
(define-constant test-alphabet (list "a" "b" "c" "d" "e"))

(define-read-only (fold-add-start-zero)
    (fold + test-list-ones u0)
)
(define-read-only (fold-add-start-ten)
    (fold + test-list-ones u10)
)
(define-read-only (fold-multiply-one)
    (fold * test-list-two u1)
)
(define-read-only (fold-multiply-two)
    (fold * test-list-two u2)
)
(define-read-only (fold-characters)
    (fold concat-string test-alphabet "")
)

(define-private (concat-string (a (string-ascii 10)) (b (string-ascii 10)))
    (unwrap-panic (as-max-len? (concat b a) u10)) 
)

;; Day 50 - Contract-call?
(define-read-only (call-basics-1-multiply)
    (contract-call? .clarity-basics-1 multiply)
)
(define-read-only (call-basics-1-hello-world)
    (contract-call? .clarity-basics-1 say-hello-world-name)
)
(define-public (call-basics-11-hello-world (name (string-ascii 48)))
    (contract-call? .clarity-basics-11 set-and-say-hello name)
)
(define-public (call-basics-111-set-second-map (new-username (string-ascii 24)) (new-balance uint))
    (begin
       (try! (contract-call? .clarity-basics-11 set-and-say-hello new-username))
       (contract-call? .clarity-basics-111 set-second-map new-username new-balance none)  
    )
)

;; Day 52 - Native NFT functions
;; (impl-trait .sip-09.nft-trait)
(define-non-fungible-token nft-test uint)
(define-public (test-mint)
    (nft-mint? nft-test u0 tx-sender)
)
(define-read-only (test-get-owner (id uint))
    (nft-get-owner? nft-test id)
)
(define-public (test-burn (id uint) (sender principal))
    (nft-burn? nft-test id sender)
)
(define-public (transfer (id uint) (sender principal) (recipient principal))
    (nft-transfer? nft-test id sender recipient)   
)

;; Day 53 - Basic Minting Logic
(define-non-fungible-token nft-test-2 uint)
(define-data-var nft-index uint u1)
(define-constant nft-limit u6)
(define-constant nft-price u10000000)
(define-constant nft-admin tx-sender)


(define-public (limited-mint metadata-url (string-ascii 256))
    (let
        (
            (current-index (var-get nft-index))
            (next-index (+ current-index u1))
        )

            ;; Assert that index < than limit
            (asserts! (< current-index nft-limit) (err "out-of-nfts")) 
            
            ;; Charge 10 STX
            (unwrap! (stx-transfer? nft-price tx-sender sender nft-admin) (err "stx-transfer")) (err u2)

            ;; Mint nft to tx-sender
            (unwrap! (nft-mint? nft-test-2 current-index tx-sender) (err "nft-mint"))

            ;; Update & store metadata url
            (map-set nft-metadata current-index metadata-url)

            ;; var-set nft-index by increasing it by one
            (ok (var-set nft-index next-index))
    )     
)

;; Day 54 - NFT Metadata Logic
(define-constant static-url "https://example.com/")
(define-map nft-metadata uint (string-ascii 256))
(define-public (get-token-uri-test-1 (id uint))
    (ok static-url)   
)
(define-public (get-token-uri-2 (id uint))
    (ok (concat 
             static-url
             (concat (uint-to-ascii id) 
             ".jason")
             
        )
             
    )   
)
(define-public (get-token-uri (id uint))
    (ok (map-get? nft-metadata id)) 
)