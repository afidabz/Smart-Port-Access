;; title: Smart-Port-Access

(define-trait nft-trait
    (
        (get-last-token-id () (response uint uint))
        (get-token-uri (uint) (response (optional (string-ascii 256)) uint))
        (get-owner (uint) (response (optional principal) uint))
        (transfer (uint principal principal) (response bool uint))
    )
)

(define-non-fungible-token container uint)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-container-not-found (err u102))
(define-constant err-already-unloaded (err u103))
(define-constant err-port-not-authorized (err u104))
(define-constant err-insufficient-balance (err u105))
(define-constant err-container-in-transit (err u106))
(define-constant err-invalid-status (err u107))

(define-data-var container-id-nonce uint u1)

(define-map containers uint {
    owner: principal,
    origin-port: (string-ascii 50),
    destination-port: (string-ascii 50),
    cargo-description: (string-ascii 100),
    fee-amount: uint,
    status: (string-ascii 20),
    created-at: uint,
    unloaded-at: (optional uint),
    paid: bool
})

(define-map authorized-ports principal bool)

(define-map port-fees principal uint)

(define-map user-balances principal uint)

(define-public (get-last-token-id)
    (ok (- (var-get container-id-nonce) u1))
)

(define-public (get-token-uri (token-id uint))
    (ok none)
)

(define-public (get-owner (token-id uint))
    (ok (nft-get-owner? container token-id))
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender sender) err-not-token-owner)
        (match (map-get? containers token-id)
            container-data (begin
                (asserts! (is-eq (get status container-data) "in-transit") err-invalid-status)
                (try! (nft-transfer? container token-id sender recipient))
                (map-set containers token-id (merge container-data { owner: recipient }))
                (ok true)
            )
            err-container-not-found
        )
    )
)

(define-public (authorize-port (port principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set authorized-ports port true)
        (ok true)
    )
)

(define-public (revoke-port-authorization (port principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-delete authorized-ports port)
        (ok true)
    )
)

(define-public (set-port-fee (port principal) (fee uint))
    (begin
        (asserts! (is-port-authorized port) err-port-not-authorized)
        (map-set port-fees port fee)
        (ok true)
    )
)

(define-public (mint-container (to principal) 
                              (origin-port (string-ascii 50))
                              (destination-port (string-ascii 50))
                              (cargo-description (string-ascii 100))
                              (fee-amount uint))
    (let 
        (
            (token-id (var-get container-id-nonce))
        )
        (asserts! (is-port-authorized tx-sender) err-port-not-authorized)
        (try! (nft-mint? container token-id to))
        (map-set containers token-id {
            owner: to,
            origin-port: origin-port,
            destination-port: destination-port,
            cargo-description: cargo-description,
            fee-amount: fee-amount,
            status: "loaded",
            created-at: stacks-block-height,
            unloaded-at: none,
            paid: false
        })
        (var-set container-id-nonce (+ token-id u1))
        (ok token-id)
    )
)

(define-public (ship-container (token-id uint))
    (match (map-get? containers token-id)
        container-data (begin
            (asserts! (is-eq tx-sender (get owner container-data)) err-not-token-owner)
            (asserts! (is-eq (get status container-data) "loaded") err-invalid-status)
            (map-set containers token-id (merge container-data { status: "in-transit" }))
            (ok true)
        )
        err-container-not-found
    )
)

(define-public (deposit-funds (amount uint))
    (let
        (
            (current-balance (default-to u0 (map-get? user-balances tx-sender)))
        )
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (map-set user-balances tx-sender (+ current-balance amount))
        (ok true)
    )
)

(define-public (unload-container (token-id uint))
    (match (map-get? containers token-id)
        container-data (begin
            (asserts! (is-port-authorized tx-sender) err-port-not-authorized)
            (asserts! (is-eq (get status container-data) "in-transit") err-invalid-status)
            (asserts! (not (get paid container-data)) err-already-unloaded)
            (let
                (
                    (owner (get owner container-data))
                    (fee-amount (get fee-amount container-data))
                    (user-balance (default-to u0 (map-get? user-balances owner)))
                )
                (asserts! (>= user-balance fee-amount) err-insufficient-balance)
                (try! (as-contract (stx-transfer? fee-amount tx-sender tx-sender)))
                (map-set user-balances owner (- user-balance fee-amount))
                (map-set containers token-id (merge container-data {
                    status: "unloaded",
                    unloaded-at: (some stacks-block-height),
                    paid: true
                }))
                (ok true)
            )
        )
        err-container-not-found
    )
)

(define-public (withdraw-funds (amount uint))
    (let
        (
            (user-balance (default-to u0 (map-get? user-balances tx-sender)))
        )
        (asserts! (>= user-balance amount) err-insufficient-balance)
        (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
        (map-set user-balances tx-sender (- user-balance amount))
        (ok true)
    )
)

(define-public (emergency-withdraw-container (token-id uint))
    (match (map-get? containers token-id)
        container-data (begin
            (asserts! (is-eq tx-sender contract-owner) err-owner-only)
            (let
                (
                    (container-age (- stacks-block-height (get created-at container-data)))
                )
                (asserts! (> container-age u1440) err-invalid-status)
                (asserts! (is-eq (get status container-data) "in-transit") err-invalid-status)
                (map-set containers token-id (merge container-data { status: "emergency-withdrawn" }))
                (ok true)
            )
        )
        err-container-not-found
    )
)

(define-read-only (get-container-info (token-id uint))
    (map-get? containers token-id)
)

(define-read-only (is-port-authorized (port principal))
    (default-to false (map-get? authorized-ports port))
)

(define-read-only (get-port-fee (port principal))
    (map-get? port-fees port)
)

(define-read-only (get-user-balance (user principal))
    (default-to u0 (map-get? user-balances user))
)

(define-read-only (get-containers-by-owner (owner principal))
    (let
        (
            (current-id (var-get container-id-nonce))
        )
        (filter-containers-by-owner owner u1 current-id)
    )
)

(define-read-only (get-containers-by-status (status (string-ascii 20)))
    (let
        (
            (current-id (var-get container-id-nonce))
        )
        (filter-containers-by-status status u1 current-id)
    )
)

(define-private (filter-containers-by-owner (target-owner principal) (start uint) (end uint))
    (fold check-container-owner (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) (list))
)

(define-private (filter-containers-by-status (target-status (string-ascii 20)) (start uint) (end uint))
    (fold check-container-status (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) (list))
)

(define-private (check-container-owner (token-id uint) (acc (list 10 uint)))
    (match (map-get? containers token-id)
        container-data (if (is-eq (get owner container-data) tx-sender)
                          (unwrap-panic (as-max-len? (append acc token-id) u10))
                          acc)
        acc
    )
)

(define-private (check-container-status (token-id uint) (acc (list 10 uint)))
    (match (map-get? containers token-id)
        container-data (if (is-eq (get status container-data) "in-transit")
                          (unwrap-panic (as-max-len? (append acc token-id) u10))
                          acc)
        acc
    )
)

(define-read-only (get-contract-balance)
    (stx-get-balance (as-contract tx-sender))
)

(begin
    (map-set authorized-ports contract-owner true)
    (map-set port-fees contract-owner u1000000)
)
