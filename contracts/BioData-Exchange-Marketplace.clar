(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-insufficient-payment (err u103))
(define-constant err-dataset-exists (err u104))
(define-constant err-invalid-access-type (err u105))
(define-constant err-subscription-expired (err u106))
(define-constant err-insufficient-stake (err u107))
(define-constant err-invalid-rating (err u405))
(define-constant err-empty-review (err u406))

(define-data-var next-dataset-id uint u1)
(define-data-var platform-fee-rate uint u5)
(define-data-var min-stake-amount uint u1000000)

(define-map datasets uint {
    owner: principal,
    title: (string-ascii 128),
    description: (string-ascii 512),
    data-hash: (buff 32),
    price-per-access: uint,
    subscription-price: uint,
    total-downloads: uint,
    revenue-earned: uint,
    is-active: bool,
    current-version: uint
})

(define-map dataset-access uint {
    user: principal,
    dataset-id: uint,
    access-type: (string-ascii 16),
    expires-at: uint,
    access-granted-at: uint
})

(define-map user-subscriptions principal {
    dataset-id: uint,
    expires-at: uint,
    is-active: bool
})

(define-map user-stakes principal {
    dataset-id: uint,
    amount: uint,
    staked-at: uint,
    reward-rate: uint
})

(define-map dataset-stakes uint {
    total-staked: uint,
    stake-count: uint,
    reward-pool: uint
})

(define-map dataset-ratings {dataset-id: uint, user: principal} {rating: uint, review: (string-ascii 256), rated-at: uint})

(define-map dataset-rating-summary uint {total-rating: uint, rating-count: uint})

(define-map dataset-versions {dataset-id: uint, version: uint} {data-hash: (buff 32), updated-at: uint, changelog: (string-ascii 256)})

(define-public (register-dataset (title (string-ascii 128)) (description (string-ascii 512)) (data-hash (buff 32)) (price-per-access uint) (subscription-price uint))
    (let
        (
            (dataset-id (var-get next-dataset-id))
        )
        (asserts! (> (len title) u0) (err u400))
        (asserts! (> price-per-access u0) (err u401))
        
        (map-set datasets dataset-id {
            owner: tx-sender,
            title: title,
            description: description,
            data-hash: data-hash,
            price-per-access: price-per-access,
            subscription-price: subscription-price,
            total-downloads: u0,
            revenue-earned: u0,
            is-active: true,
            current-version: u1
        })
        
        (map-set dataset-stakes dataset-id {
            total-staked: u0,
            stake-count: u0,
            reward-pool: u0
        })

        (map-set dataset-rating-summary dataset-id {
            total-rating: u0,
            rating-count: u0
        })

        (map-set dataset-versions {dataset-id: dataset-id, version: u1} {
            data-hash: data-hash,
            updated-at: burn-block-height,
            changelog: ""
        })

        (var-set next-dataset-id (+ dataset-id u1))
        (ok dataset-id)
    )
)

(define-public (purchase-access (dataset-id uint))
    (let
        (
            (dataset (unwrap! (map-get? datasets dataset-id) err-not-found))
            (price (get price-per-access dataset))
            (owner (get owner dataset))
            (platform-fee (/ (* price (var-get platform-fee-rate)) u100))
            (owner-payment (- price platform-fee))
        )
        (asserts! (get is-active dataset) (err u402))
        
        (try! (stx-transfer? price tx-sender (as-contract tx-sender)))
        (try! (as-contract (stx-transfer? owner-payment tx-sender owner)))
        
        (map-set dataset-access (+ (* dataset-id u1000000) burn-block-height) {
            user: tx-sender,
            dataset-id: dataset-id,
            access-type: "single",
            expires-at: (+ burn-block-height u1),
            access-granted-at: burn-block-height
        })
        
        (map-set datasets dataset-id (merge dataset {
            total-downloads: (+ (get total-downloads dataset) u1),
            revenue-earned: (+ (get revenue-earned dataset) owner-payment)
        }))
        
        (ok true)
    )
)

(define-public (purchase-subscription (dataset-id uint) (duration-blocks uint))
    (let
        (
            (dataset (unwrap! (map-get? datasets dataset-id) err-not-found))
            (base-price (get subscription-price dataset))
            (total-price (* base-price (/ duration-blocks u1000)))
            (owner (get owner dataset))
            (platform-fee (/ (* total-price (var-get platform-fee-rate)) u100))
            (owner-payment (- total-price platform-fee))
            (expires-at (+ burn-block-height duration-blocks))
        )
        (asserts! (get is-active dataset) (err u402))
        (asserts! (> duration-blocks u0) (err u403))
        
        (try! (stx-transfer? total-price tx-sender (as-contract tx-sender)))
        (try! (as-contract (stx-transfer? owner-payment tx-sender owner)))
        
        (map-set user-subscriptions tx-sender {
            dataset-id: dataset-id,
            expires-at: expires-at,
            is-active: true
        })
        
        (map-set datasets dataset-id (merge dataset {
            revenue-earned: (+ (get revenue-earned dataset) owner-payment)
        }))
        
        (ok expires-at)
    )
)

(define-public (stake-for-access (dataset-id uint) (amount uint))
    (let
        (
            (dataset (unwrap! (map-get? datasets dataset-id) err-not-found))
            (current-stakes (default-to {total-staked: u0, stake-count: u0, reward-pool: u0} 
                           (map-get? dataset-stakes dataset-id)))
        )
        (asserts! (>= amount (var-get min-stake-amount)) err-insufficient-stake)
        (asserts! (get is-active dataset) (err u402))
        
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        (map-set user-stakes tx-sender {
            dataset-id: dataset-id,
            amount: amount,
            staked-at: burn-block-height,
            reward-rate: u10
        })
        
        (map-set dataset-stakes dataset-id {
            total-staked: (+ (get total-staked current-stakes) amount),
            stake-count: (+ (get stake-count current-stakes) u1),
            reward-pool: (get reward-pool current-stakes)
        })
        
        (ok true)
    )
)

(define-public (unstake (dataset-id uint))
    (let
        (
            (stake-info (unwrap! (map-get? user-stakes tx-sender) err-not-found))
            (stake-amount (get amount stake-info))
            (blocks-staked (- burn-block-height (get staked-at stake-info)))
            (reward (/ (* stake-amount (get reward-rate stake-info) blocks-staked) u100000))
            (current-stakes (unwrap! (map-get? dataset-stakes dataset-id) err-not-found))
        )
        (asserts! (is-eq (get dataset-id stake-info) dataset-id) err-unauthorized)
        
        (try! (as-contract (stx-transfer? stake-amount tx-sender tx-sender)))
        (try! (as-contract (stx-transfer? reward tx-sender tx-sender)))
        
        (map-delete user-stakes tx-sender)
        
        (map-set dataset-stakes dataset-id {
            total-staked: (- (get total-staked current-stakes) stake-amount),
            stake-count: (- (get stake-count current-stakes) u1),
            reward-pool: (get reward-pool current-stakes)
        })
        
        (ok (+ stake-amount reward))
    )
)

(define-public (rate-dataset (dataset-id uint) (rating uint) (review (string-ascii 256)))
    (let
        (
            (current-summary (default-to {total-rating: u0, rating-count: u0} (map-get? dataset-rating-summary dataset-id)))
        )
        (asserts! (has-access tx-sender dataset-id) err-unauthorized)
        (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
        (asserts! (> (len review) u0) err-empty-review)
        (map-set dataset-ratings {dataset-id: dataset-id, user: tx-sender} {rating: rating, review: review, rated-at: burn-block-height})
        (map-set dataset-rating-summary dataset-id {
            total-rating: (+ (get total-rating current-summary) rating),
            rating-count: (+ (get rating-count current-summary) u1)
        })
        (ok true)
    )
)

(define-public (deactivate-dataset (dataset-id uint))
    (let
        (
            (dataset (unwrap! (map-get? datasets dataset-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get owner dataset)) err-unauthorized)
        
        (map-set datasets dataset-id (merge dataset {is-active: false}))
        (ok true)
    )
)

(define-public (update-platform-fee (new-fee-rate uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= new-fee-rate u20) (err u404))
        (var-set platform-fee-rate new-fee-rate)
        (ok true)
    )
)

(define-public (update-min-stake (new-min-stake uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set min-stake-amount new-min-stake)
        (ok true)
    )
)

(define-public (update-dataset-version (dataset-id uint) (new-data-hash (buff 32)) (changelog (string-ascii 256)))
    (let
        (
            (dataset (unwrap! (map-get? datasets dataset-id) err-not-found))
            (current-version (get current-version dataset))
            (new-version (+ current-version u1))
        )
        (asserts! (is-eq tx-sender (get owner dataset)) err-unauthorized)
        (asserts! (get is-active dataset) (err u402))
        (map-set dataset-versions {dataset-id: dataset-id, version: new-version} {
            data-hash: new-data-hash,
            updated-at: burn-block-height,
            changelog: changelog
        })
        (map-set datasets dataset-id (merge dataset {
            data-hash: new-data-hash,
            current-version: new-version
        }))
        (ok new-version)
    )
)

(define-public (update-dataset-price (dataset-id uint) (new-price-per-access uint) (new-subscription-price uint))
    (let
        (
            (dataset (unwrap! (map-get? datasets dataset-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get owner dataset)) err-unauthorized)
        (asserts! (get is-active dataset) (err u402))
        (asserts! (> new-price-per-access u0) (err u401))
        (asserts! (> new-subscription-price u0) (err u401))
        (map-set datasets dataset-id (merge dataset {
            price-per-access: new-price-per-access,
            subscription-price: new-subscription-price
        }))
        (ok true)
    )
)

(define-read-only (get-dataset (dataset-id uint))
    (map-get? datasets dataset-id)
)

(define-read-only (get-user-subscription (user principal))
    (map-get? user-subscriptions user)
)

(define-read-only (get-user-stake (user principal))
    (map-get? user-stakes user)
)

(define-read-only (get-dataset-stakes (dataset-id uint))
    (map-get? dataset-stakes dataset-id)
)

(define-read-only (has-access (user principal) (dataset-id uint))
    (let
        (
            (subscription (map-get? user-subscriptions user))
            (stake (map-get? user-stakes user))
        )
        (or
            (and (is-some subscription) 
                 (> (get expires-at (unwrap-panic subscription)) burn-block-height)
                 (is-eq (get dataset-id (unwrap-panic subscription)) dataset-id))
            (and (is-some stake) 
                 (is-eq (get dataset-id (unwrap-panic stake)) dataset-id))
        )
    )
)

(define-read-only (get-platform-fee-rate)
    (var-get platform-fee-rate)
)

(define-read-only (get-min-stake-amount)
    (var-get min-stake-amount)
)

(define-read-only (get-next-dataset-id)
    (var-get next-dataset-id)
)

(define-read-only (calculate-subscription-cost (dataset-id uint) (duration-blocks uint))
    (match (map-get? datasets dataset-id)
        dataset (ok (* (get subscription-price dataset) (/ duration-blocks u1000)))
        err-not-found
    )
)

(define-read-only (get-dataset-average-rating (dataset-id uint))
    (let
        (
            (summary (default-to {total-rating: u0, rating-count: u0} (map-get? dataset-rating-summary dataset-id)))
            (count (get rating-count summary))
        )
        (if (> count u0)
            (ok (/ (get total-rating summary) count))
            (ok u0)
        )
    )
)

(define-read-only (calculate-stake-reward (user principal) (dataset-id uint))
    (match (map-get? user-stakes user)
        stake-info 
            (let
                (
                    (blocks-staked (- burn-block-height (get staked-at stake-info)))
                    (stake-amount (get amount stake-info))
                    (reward-rate (get reward-rate stake-info))
                )
                (ok (/ (* stake-amount reward-rate blocks-staked) u100000))
            )
        err-not-found
    )
)
