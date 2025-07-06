;; Provider Verification Contract
;; Validates disability assistance service providers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROVIDER_EXISTS (err u101))
(define-constant ERR_PROVIDER_NOT_FOUND (err u102))

(define-map verified-providers
  principal
  {
    name: (string-ascii 100),
    specialization: (string-ascii 100),
    certification-level: uint,
    verified-at: uint,
    active: bool
  }
)

(define-map provider-ratings
  principal
  {
    total-rating: uint,
    rating-count: uint,
    average-rating: uint
  }
)

(define-public (register-provider (name (string-ascii 100)) (specialization (string-ascii 100)) (certification-level uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? verified-providers tx-sender)) ERR_PROVIDER_EXISTS)
    (map-set verified-providers tx-sender {
      name: name,
      specialization: specialization,
      certification-level: certification-level,
      verified-at: block-height,
      active: true
    })
    (ok true)
  )
)

(define-public (update-provider-status (provider principal) (active bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? verified-providers provider)) ERR_PROVIDER_NOT_FOUND)
    (map-set verified-providers provider
      (merge (unwrap-panic (map-get? verified-providers provider)) {active: active})
    )
    (ok true)
  )
)

(define-public (rate-provider (provider principal) (rating uint))
  (let (
    (current-ratings (default-to {total-rating: u0, rating-count: u0, average-rating: u0}
                                (map-get? provider-ratings provider)))
    (new-total (+ (get total-rating current-ratings) rating))
    (new-count (+ (get rating-count current-ratings) u1))
    (new-average (/ new-total new-count))
  )
    (asserts! (and (>= rating u1) (<= rating u5)) (err u103))
    (asserts! (is-some (map-get? verified-providers provider)) ERR_PROVIDER_NOT_FOUND)
    (map-set provider-ratings provider {
      total-rating: new-total,
      rating-count: new-count,
      average-rating: new-average
    })
    (ok true)
  )
)

(define-read-only (get-provider-info (provider principal))
  (map-get? verified-providers provider)
)

(define-read-only (get-provider-rating (provider principal))
  (map-get? provider-ratings provider)
)

(define-read-only (is-verified-provider (provider principal))
  (match (map-get? verified-providers provider)
    provider-info (get active provider-info)
    false
  )
)
