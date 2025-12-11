;; Artist-Discography
;; Contract that models an artist discography (discography -> albums -> tracks)
;; written by Rogersterkaa

;; Discography
;; An artist discography is a list of albums
;; The artist or the admin can start a dicography & can add/remove albums

;; Album
;; An album is a list of tracks + some additional info (such as when it was published)
;; The artist or the admin can start an album & can add/remove tracks

;; Track
;; A track is made up of a name + duration (in seconds) and a possible feature (optional feature)
;; The artist or the admin can start a track and can add/remove tracks

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; cons, vars, and maps ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; admin list of principals
(define-data-var admins (list 10 principal) (list tx-sender))

;; Map that keeps track of a single track
(define-map track { artist:principal, album-id: uint, track-id: uint } { 
    title: (string-ascii 24), 
    duration: uint,
    feature: (optional principal)
})

;; Map that keeps track of a single album
(define-map album { artist: principal, album-id: uint } { 
    title: (string-ascii 24),
    tracks: (list 20 uint),
    height-published: uint
})

;;Map that keeps track of a discography
(define-map discography principal (list 10 uint))



;;;;;;;;;;;;;;;;;;;;;;;;
;;;; read functions ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;

;; Get track data
(define-read-only (get-track-data (artist principal) (album-id uint) (track-id uint))
    (map-get? track {artist: artist, album-id: album-id, track-id: track-id})
)

;; Get featured artist
(define-read-only (get-featured-artist (artist principal) (album-id uint) (track-id uint))
    (get feature (map-get? track {artist: artist, album-id: album-id, track-id: track-id}))
)

;; Get album data
(define-read-only (get-album-data (artist principal) (album-id uint))
    (map-get? album { artist: artist, album-id: album-id })
)
;; Get published
(define-read-only (get-album-published-height (artist principal) (album-id uint))
    (get height-published (map-get? album { artist: artist, album-id: album-id }))
)
;; Get discography
(define-read-only (get-discography (artist principal))
    (map-get? discography artist)
)

;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; write functions ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;

;; Add a track
;; @desc - function that allows a user or admin to add a track
;; @param - title - (string-ascii 24), duration - uint, featured artist - (optional principal) album-id (uint)

(define-public (add-a-track (artist principal) (title (string-ascii 24)) (duration uint) (featured (optional principal)) (album-id uint))
    (let
        (
            (current-discography (unwrap! (map-get? discography {artist: artist}) (err u0)))
            (current-album (unwrap! (index-of current-discography album-id) (err u2)))
            (current-album-data (unwrap! (map-get? album {artist: artist, album-id: album-id}) (err u3)))
            (current-album-tracks (get tracks current-album-data))
            (current-album-track-id (len current-album-tracks))
            (next-album-track-id (+ u1 current-album-track-id))
        )

        ;; assert that tx-sender is either artist or admin
        (asserts! (or (is-eq tx-sender artist) (is-some (index-of (var-get admins) tx-sender))) (err u1))

        ;; assert that duration is less than 600 (10 minutes)
        (asserts! (< duration u600) (err u3))

        ;; map-set new track
        (map-set track {artist: artist, album-id: album-id, track-id: next-album-track-id} {
           title: title,
           duration: duration,
           featured: featured
        })

        ;; map-set album map by appending new track to album
        (map-set album {artist: artist, album-id: album-id}
            (merge
                current-album-data
                {tracks: (unwrap! (as-max-len? (append current-album-tracks next-album-track-id) u10) (err u4))}   
            ) 
        )
        (ok true)
    )
)

;; Add an album
;; @desc - function that allows the artist or admin to add a new album or start a new discography & then add album
(define-public (add-album-or-create-discography-and-add-album (artist principal) (album-title (string-ascii 24)))
    (let
        (
            (current-discography (default-to (list) (map-get? discography {artist: artist})))
            (current-album-id (len current-discography))
            (next-album-id (+ u1 current-album-id))
        )
            
        ;; check whether discography exists / if discography is-some
        (if (is-eq current-album-id u0)
            ;; empty discography
            (begin 
                (map-set discography {artist: artist} (list u0))
                (map-set album {artist: artist, album-id: u0} {
                    title: album-title,
                    tracks: (list),
                    height-published: block-height
                })
                (ok true)
            )
            ;; discography exists
            (begin
                (map-set discography {artist: artist} (unwrap! (as-max-len? (append current-discography next-album-id) u10) (err u4)))
                (map-set album {artist: artist, album-id: next-album-id} {
                    title: album-title,
                    tracks: (list),
                    height-published: block-height    
                })
                (ok true)
            )
        )
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Admin functions ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;

;; Add Admin
;; @desc - functions that an existing admin can call to add another admin
;; @param - new admin (principal)
(define-public (add-admin (new-admin principal))
    (let
        (
            (admins-list (var-get admins))
        )
    
        ;; assert that tx-sender is an existing admin
        (asserts! (is-some (index-of admins-list tx-sender)) (err u100))

        ;; assert that new admin does not exist in admin list
        (asserts! (is-none (index-of admins-list new-admin)) (err u101))

        ;; append new-admin to admin list
        (var-set admins (unwrap! (as-max-len? (append admins-list new-admin) u100) (err u102)))

        (ok true)
    )
)

;; Remove admin
;; @desc - functions that removes an existing admin
;; @param - removed admin (principal)
(define-public (remove-admin (removed-admin principal))
    (let
        (
            (admins-list (var-get admin))
            (admin-index (unwrap! (index-of admins-list removed-admin) (err u103)))
            (updated-admins (filter admins-list (not (is-eq removed-admin element))))
        )
        ;; assert that tx-sender is an existing admin
        (asserts! (is-some (index-of admins-list tx-sender)) (err u100))

        ;; assert that removed-admin IS an existing admin
        (asserts! (is-some admin-index) (err u103))

        ;; remove admin from admin list
        (ok (var-set admins updated-admins))
    )
)