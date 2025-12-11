;; NFT Advance
;; An advance NFT that has all modern functions required for a high-quality project
;; Written by Rogersterkaa

;; Unique properties & features
;; 1. Implements non-custodial marketplace functions
;; 2. Implements a whitelist minting system
;; 3. Option to mint 1,2 or 5
;; 4. Multiple admin system

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; cons, vars, and maps ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Define NFT
(define-non-fungible-token advance-nft uint)

;; Adhere to SIP09
;; (impl-trait .sip-09.nft-trait)

;; Collection limit
(define-constant collection-limit u10)

;; Root URI
(define-constant collection-root-uri "https://example.com/metadata/")

;; NFT price
(define-constant advance-nft-price u10000000)

;;Collection Index
(define-data-var collection-index uint u1)

;; Admin Deployer
(define-constant deployer tx-sender)

;; Admin list
(define-data-var admins (list 10 principal) (list tx-sender))

;; Marketplace map
(define-map market uint {
    price: uint,
    owner: principal
})

;; Whitelist map
(define-map whitelist-map principal uint)

;;;;;;;;;;;;;;;;;;;;;;;;
;;; SIP-09 Functions ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

;; Get last token id
(define-public (get-last-token-id)
    (ok (var-get collection-index))
)

;; Get token URI
(define-public (get-token-uri (id uint))
    (ok
        (some (concat
            collection-root-uri
            (concat
                (uint-to-ascii id)
                ".jason"
            )
        ))
    )
)

;; Get token owner
(define-public (get-token-owner)
    (ok (nft-get-owner? advance-nft id))
)

;; Transfer
(define-public (transfer (id uint) (sender principal) (recipient principal))
    (begin 
        (asserts! (is-eq tx-sender sender) (err u1)) 
        (if (is-some (map-get? market id))
            (map-delete market id)
            false
        )
        (nft-transfer? advance-nft id sender recipient)
    )
)


;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Non-custidial Funcs ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; List in ustx
(define-public (list-in-ustx (item uint) (price uint))
    (let
        (
            (nft-owner (unwrap! (nft-get-owner? advance-nft item) (err "err-nft-doesnt-exist")))
        )

        ;; Assert that tx-sender is the current owner
        (asserts! (is-eq nft-owner tx-sender) (err "err-not-owner"))

        ;; Map-set and update market
        (ok (map-set market item {
            price: price,
            owner: tx-sender
        }))
    )
)

;; Unlist in ustx
(define-public (unlist-in-ustx (item uint))
    (let 
        (
            (current-listing (unwrap! (map-get? market item) (err "err-not-listed")))
            (current-price (get-price current-listing))
            (currrent-owner (get-owner current-listing))
        )

        ;; Assert that tx-sender is current owner
        (asserts! (is-eq tx-sender current-owner) (err "err-not-owner"))

        ;; Delete the listing
        (ok (map-delete market item)) 
    )
)

;; Buy in ustx
(define-public (buy-in-ustx (item uint))
    (let 
        (
             (current-listing (unwrap! (map-get? market item) (err "err-not-listed")))
            (current-price (get-price current-listing))
            (currrent-owner (get-owner current-listing))  
        )

        ;; Send stx to start purchase
        (unwrap! (stx-transfer? current-price tx-sender current-owner) (err "err-stx-transfer"))

        ;; Send NFt to purchaser 
        (unwrap! (nft-transfer? advance-nft item current-owner tx-sender) (err "err-nft-transfer"))

        ;; Delete the listing
         (ok (map-delete market item))
    )
)

;; Check listing
(define-read-only (check-listing (item uint))
    (map-get? market item)
)



;;;;;;;;;;;;;;;;;;;;;;
;;; Mint Functions ;;;
;;;;;;;;;;;;;;;;;;;;;;

;; Mint 1
(define-public (mint-1)
    (let 
        (
            (current-index (var-get collection-index))
            (next-index (+ u1 current-index))
            (whitelist-mint (unwrap! (map-get? whitelist-map tx-sender) (err "err-not-whielisted")))
        )

        ;; Assert that collection is not minted out (collection-index < collection-limit)
        (asserts! (< current-index (var-get collection-index)) (err "err-minted-out"))

        ;; Assert that user has mints left (whitelist-mint > 0)
        (asserts! (> whitelist-mints u0) (err "err-no-whitelist-mints-left"))

        ;; STX transfer / pay for the mint
        (unwrap! (stx-transfer? advance-nft-price tx-sender deployer) (err "err-st-transfer")) 

        ;; Mint NFT to tx-sender 
        (unwrap! (nft-mint? advance-nft current-index tx-sender) (err "err-nft-mint"))

        ;; Var-set collection-index to next index
        (var-set collection-index next-index)

        ;; Map-set whitelist-mints to whitelist-mints - 1
        (ok (map-set whitelist-map tx-sender (- whitelist-mints u1)))
    )
)

;; Mint 2
(define-public (mint-two)
    (begin 
        (unwrap! (mint-one) (err "err-mint-1"))
        (ok (unwrap! (mint-one) (err "err-mint-2")))
    )
)

;; Mint 5
(define-public (mint-five)
    (begin 
        (unwrap! (mint-one) (err "err-mint-1"))
        (unwrap! (mint-one) (err "err-mint-2"))
        (unwrap! (mint-one) (err "err-mint-3"))
        (unwrap! (mint-one) (err "err-mint-4"))
        (ok (unwrap! (mint-one) (err "err-mint-5")))
    )
)



;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Whitelist Functions ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Add whitelist
(define-public (whitelist-principal (user principal) (mints uint))
    (let
        (
           (whitelist-mint (map-get? whitelist-map user)) 
        )

        ;; Assert that tx-sender is an admin

        ;; Assert that whitelist-mint is-none

        ;; Map-set the whitelist-map

        (ok tru)
    )
)

;; check whitelist status




;;;;;;;;;;;;;;;;;;;;;;;
;;; Admin Functions ;;;
;;;;;;;;;;;;;;;;;;;;;;;

;; Add admin

;; Remove admin

;; Remove admin helper


;;;;;;;;;;;;;;;;;;;;;;;;
;;; Helper Functions ;;;
;;;;;;;;;;;;;;;;;;;;;;;;