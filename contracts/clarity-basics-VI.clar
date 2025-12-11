;; title: clarity-basics-VI
;; Reviewing more clarity fundamentals
;; Written by Rogersterkaa

;; Day 57 - Minting Whitelist Logic
;; A whitelist is what you use when you want to write a smart contract on nft that only allows specific addresses you provided to be minted
(define-non-fungible-token test-nft uint)
(define-constant collection-limit u10)
(define-constant admin tx-sender)
(define-data-var collection-index uint u1)

(define-map whitelist-map principal uint)

;; Minting Logic
(define-public (mint)
    (let
        (
            (current-index (var-get collection-index))
            (next-index (+ u1 current-index))
            (current-whitelist-mints (unwrap! (map-get? whitelist-map tx-sender) (err "err-whitelist-map-none")))
        )

        ;; Assert that current-index < collection limit
        (asserts! (< current-index collection-limit) (err "err-no-mints-left"))

        ;; assert that tx-sender has whitelist mints remaining
        (asserts! (> current-whitelist-mints u0) (err "err-whitelist-mints-all-used"))

        ;; Mint
        (unwrap! (nft-mint? test-nft current-index tx-sender) (err "err-minting"))

         ;; Update allocated whitelist mints
        (map-set whitelist-map tx-sender (- current-whitelist-mints u1))

        ;; Increase current-index
        (ok (var-set collection-index next-index))

    )

)

;; Add principal to whitelist
(define-public (whitelist-principal (whitelist-address principal) (mints-allocated uint))
    (begin
 
        ;; Assert that tx-sender is admin
        (asserts! (is-eq tx-sender admin) (err "err-not-admin"))

        ;; Map-set whitelist-map
        (ok (map-set whitelist-map whitelist-address mints-allocated))  

    )
)


;; Day 58 - Non-Custodial Marketplace Functions
;; When planning to build a market place for NFTs, the default way to do this is to build a contract that takes custody of the NFTs
;; The most common way NFTs are written, only the person that owns the contract can transfer
;; Market place listing of NFT is a function that allows contract owner to list NFT to the market place contract for interested buyers to purchase
;; The unlist function allows the owner of an NFT take it back to himself from the market place contract.
;; While the buy function allows any principal to buy a listed NFT from the market place.
(define-map market uint {price: uint, owner: principal})
(define-public (list-ustx (item uint) (price uint))
    (let
        (
            (nft-owner (unwrap! (nft-get-owner? test-nft item) (err "err-nft-doesnt-exist")))
        )

        ;; Asserts that tx-sender is-eq to the NFT-owner
        (asserts! (is-eq tx-sender nft-owner) (err "err-not-owner"))

        ;; Map set market with new NFT
        (ok (map-set market item {price: price, owner: tx-sender }))
    )  
)
(define-read-only (get-list-in-ustx (item uint))
    (map-get? market item)
)
(define-public (unlist-in-ustx (item uint))
    (let 
        (
           (current-listing (unwrap! (map-get? market item) (err "err-listing-doesnt-exist")))
           (current-price (get price current-listing))
           (current-owner (get owner current-listing))
        ) 

           ;; Asserts that tx-sender is current owner 
           (asserts! (is-eq tx-sender current-owner) (err "err-not-owner"))

           ;; Map delete existing listing
           (ok (map-delete market item))
        
    )
)
(define-public (buy-in-ustx (item uint))
    (let 
        (
            (current-listing (unwrap! (map-get? market item) (err "err-listing-doesnt-exist")))
            (current-price (get price current-listing))
            (current-owner (get owner current-listing))
        )

        ;; Tx-sender buys by transfering STX
        (unwrap! (stx-transfer? current-price tx-sender current-owner) (err "err-STX-transfer"))

        ;; Tranfer NFT to new buyer
        (unwrap! (nft-transfer? test-nft item current-owner tx-sender) (err "err-nft-transfer")) 

        ;; Map delete the listing
        (ok (map-delete market item))
    )
)