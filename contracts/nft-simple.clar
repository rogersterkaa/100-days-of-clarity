;; NFT simple
;; The most simple NFT
;; Written by Rogersterkaa

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; cons, vars, and maps ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Define NFT
(define-non-fungible-token simple-nft uint)

;; Adhere to SIP09
(impl-trait .sip-09.nft-trait)

;; Collection limit
(define-constant collection-limit u100)

;; Root URI
(define-constant collection-root-uri "https://example.com/metadata/")

;; NFT price
(define-constant simple-nft-price u10000000)

;;Collection Index
(define-data-var collection-index uint u1)


;;;;;;;;;;;;;;;;;;;;;;;
;;; SIP-09 Functions;;;
;;;;;;;;;;;;;;;;;;;;;;;

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
    (ok (nft-get-owner? simple-nft id))
)

;; Transfer
(define-public (transfer (id uint) (sender principal) (recipient principal))
    (begin 
        (asserts! (is-eq tx-sender sender) (err u1)) 
        (nft-transfer? simple-nft id sender recipient)
    )
)



;;;;;;;;;;;;;;;;;;;;;
;;; Core Functions;;;
;;;;;;;;;;;;;;;;;;;;;

;; Core Mint Functions
;; @desc - core functions used for minting one nft-simple
(define-public (mint)
    (let
        (
            (current-indext (var-get collection index))
            (next-index (+ current-index u1))
        )

        ;; assert that current-index < than collection-limit 
        (asserts! (< current-index collection-limit) (err "err-minted-out"))

        ;; Charge tx-sender for simple-nft
        (unwrap! (stx-transfer? simple-nft-price tx-sender (as-contract tx-sender)) (err "err-stx-tranfer"))

        ;; Mint NFT 
        (unwrap! (nft-mint? test-nft current-index tx-sender) (err "err-minting"))

        ;; Var-set collection-index to next-index
        (ok (var-set collection-index next-index tx-sender))
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Helper Functions ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

;; @desc utility function that takes in a unit & returns a string
;; @param value: the unit we are casting into a string concatenate
