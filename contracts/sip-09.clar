;; SIP-09
;; Implementing SIP-09 locally so we can work with NFTS correctly
;; Written by Rogersterkaa
;; Day 51
;; A Trait is nothing more than a list of function signatures, it is not the actual implementattion of functions but just the signature(the name,parameters,protypes)
(define-trait nft-trait 
    (
        ;; Last token ID
        (get-last-token-id () (response uint uint))
        ;; URI metadata
        (get-token-uri (uint) (response (optional (string-ascii 256)) uint))
        ;; Get token owner
        (get-owner (uint) (response (optional principal) uint))
        ;; Transfer
        (transfer (uint principal principal) (response bool uint))
    )
)