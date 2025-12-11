;; community-hello-world
;; contract that provides a simple community billboard, readable by anyone but only updatable by the Admins permission



;;;;;;;;;;;;;;;;;;;;;;;;;;
;; cons, vars, and maps ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

;; constant that sets deployer principal as admin
(define-constant admin tx-sender)

;; Error-Messages
(define-constant ERR-TX-SENDER-NOT-NEXT-USER (err u0))

;; varibles that keeps track of the *next* user that will introduce themselves/ write to the billboard
(define-data-var next-user principal tx-sender)

;; variable tuple that contains new member info
(define-data-var billboard {new-user-principal: principal, new-user-name: (string-ascii 24)} {
      new-user-principal: tx-sender,
      new-user-name: ""
})



;;;;;;;;;;;;;;;;;;;;
;; read functions ;;
;;;;;;;;;;;;;;;;;;;;

;; community get billboard
(define-read-only (get-billboard)
  (var-get billboard)
)

;; get next user
(define-read-only (get-next-user)
  (var-get next-user)
)



;;;;;;;;;;;;;;;;;;;;;
;; write functions ;;
;;;;;;;;;;;;;;;;;;;;;

;; update billboard
;; @desc function used by new-user to update the community billboard
;; @param new-name: (string-ascii 24)
(define-public (update-billboard (updated-user-name (string-ascii 24)))
    (begin
        ;; assert that tx-sender is the next user (Approved by admin)
        (asserts! (is-eq tx-sender (var-get next-user)) ERR-TX-SENDER-NOT-NEXT-USER)

        ;; assert that updated-user-name is not empty
        (asserts! (not (is-eq updated-user-name "")) ERR-TX-SENDER-NOT-NEXT-USER)

        ;; var-set billboard with new keys
        (var-set billboard {
            new-user-principal: tx-sender,
            new-user-name: updated-user-name
        })
        (ok true)
    )
)

;; admin set new user
;; @desc function used by admin to set/ give permission to next user
;; @param updated-user principal: principal
(define-public (admin-set-new-user (updated-user-principal principal))
    (begin
        ;; assert that tx-sender is admin
        (asserts! (is-eq tx-sender admin) ERR-TX-SENDER-NOT-NEXT-USER)

        ;; assert that updated-user-principal is NOT admin
        (asserts! (not (is-eq updated-user-principal admin)) ERR-TX-SENDER-NOT-NEXT-USER)

        ;; assert that updated-user-principal is NOT the current next-user
        (asserts! (not (is-eq updated-user-principal (var-get next-user))) ERR-TX-SENDER-NOT-NEXT-USER)

        ;; var-set next-user to updated-user-principal
       (ok (var-set next-user updated-user-principal))
    )
)