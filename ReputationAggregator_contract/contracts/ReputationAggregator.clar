
;; title: ReputationAggregator
;; version: 1.0.0
;; summary: Cross-platform reputation score aggregation and normalization system
;; description: A smart contract that aggregates reputation scores from multiple platforms
;;              and provides normalized reputation metrics for addresses

;; traits
;;

;; token definitions
;;

;; constants
;;
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_PLATFORM (err u101))
(define-constant ERR_INVALID_SCORE (err u102))
(define-constant ERR_PLATFORM_NOT_FOUND (err u103))
(define-constant ERR_ADDRESS_NOT_FOUND (err u104))
(define-constant MIN_SCORE u0)
(define-constant MAX_SCORE u100)

;; data vars
;;
(define-data-var contract-owner principal CONTRACT_OWNER)
(define-data-var platform-count uint u0)

;; data maps
;;
;; Store platform information
(define-map platforms
  { platform-id: uint }
  {
    name: (string-ascii 64),
    weight: uint,
    is-active: bool,
    created-at: uint
  }
)

;; Store reputation scores for each address on each platform
(define-map reputation-scores
  { address: principal, platform-id: uint }
  {
    score: uint,
    last-updated: uint,
    total-interactions: uint
  }
)

;; Store aggregated reputation data for addresses
(define-map aggregated-reputation
  { address: principal }
  {
    total-score: uint,
    weighted-score: uint,
    platform-count: uint,
    last-calculated: uint
  }
)

;; Store authorized platform operators
(define-map platform-operators
  { operator: principal, platform-id: uint }
  { is-authorized: bool }
)

;; public functions
;;

;; Register a new platform
(define-public (register-platform (name (string-ascii 64)) (weight uint))
  (let
    (
      (new-platform-id (+ (var-get platform-count) u1))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (asserts! (and (>= weight u1) (<= weight u100)) ERR_INVALID_SCORE)

    (map-set platforms
      { platform-id: new-platform-id }
      {
        name: name,
        weight: weight,
        is-active: true,
        created-at: block-height
      }
    )

    (var-set platform-count new-platform-id)
    (ok new-platform-id)
  )
)

;; Update platform status (activate/deactivate)
(define-public (update-platform-status (platform-id uint) (is-active bool))
  (let
    (
      (platform (unwrap! (map-get? platforms { platform-id: platform-id }) ERR_PLATFORM_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)

    (map-set platforms
      { platform-id: platform-id }
      (merge platform { is-active: is-active })
    )
    (ok true)
  )
)

;; Authorize platform operator
(define-public (authorize-platform-operator (operator principal) (platform-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? platforms { platform-id: platform-id })) ERR_PLATFORM_NOT_FOUND)

    (map-set platform-operators
      { operator: operator, platform-id: platform-id }
      { is-authorized: true }
    )
    (ok true)
  )
)

;; Submit reputation score for an address on a platform
(define-public (submit-reputation-score (address principal) (platform-id uint) (score uint) (interactions uint))
  (let
    (
      (platform (unwrap! (map-get? platforms { platform-id: platform-id }) ERR_PLATFORM_NOT_FOUND))
      (is-authorized (default-to false (get is-authorized (map-get? platform-operators { operator: tx-sender, platform-id: platform-id }))))
    )
    (asserts! (or (is-eq tx-sender (var-get contract-owner)) is-authorized) ERR_UNAUTHORIZED)
    (asserts! (get is-active platform) ERR_INVALID_PLATFORM)
    (asserts! (and (>= score MIN_SCORE) (<= score MAX_SCORE)) ERR_INVALID_SCORE)

    (map-set reputation-scores
      { address: address, platform-id: platform-id }
      {
        score: score,
        last-updated: block-height,
        total-interactions: interactions
      }
    )

    ;; Trigger aggregation calculation
    (let
      (
        (aggregation-result (calculate-reputation-internal address))
      )
      (map-set aggregated-reputation
        { address: address }
        {
          total-score: (get total-score aggregation-result),
          weighted-score: (get weighted-score aggregation-result),
          platform-count: (get platform-count aggregation-result),
          last-calculated: block-height
        }
      )
      (ok true)
    )
  )
)

;; Calculate and store aggregated reputation for an address
(define-public (calculate-aggregated-reputation (address principal))
  (let
    (
      (aggregation-result (calculate-reputation-internal address))
    )
    (map-set aggregated-reputation
      { address: address }
      {
        total-score: (get total-score aggregation-result),
        weighted-score: (get weighted-score aggregation-result),
        platform-count: (get platform-count aggregation-result),
        last-calculated: block-height
      }
    )
    (ok aggregation-result)
  )
)

;; Transfer contract ownership
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (var-set contract-owner new-owner)
    (ok true)
  )
)

;; read only functions
;;

;; Get platform information
(define-read-only (get-platform (platform-id uint))
  (map-get? platforms { platform-id: platform-id })
)

;; Get reputation score for address on specific platform
(define-read-only (get-reputation-score (address principal) (platform-id uint))
  (map-get? reputation-scores { address: address, platform-id: platform-id })
)

;; Get aggregated reputation for an address
(define-read-only (get-aggregated-reputation (address principal))
  (map-get? aggregated-reputation { address: address })
)

;; Get normalized reputation score (0-100 scale)
(define-read-only (get-normalized-reputation (address principal))
  (match (map-get? aggregated-reputation { address: address })
    aggregated-data (ok (get weighted-score aggregated-data))
    ERR_ADDRESS_NOT_FOUND
  )
)

;; Check if operator is authorized for a platform
(define-read-only (is-platform-operator (operator principal) (platform-id uint))
  (default-to false (get is-authorized (map-get? platform-operators { operator: operator, platform-id: platform-id })))
)

;; Get contract owner
(define-read-only (get-contract-owner)
  (var-get contract-owner)
)

;; Get total number of platforms
(define-read-only (get-platform-count)
  (var-get platform-count)
)

;; private functions
;;

;; Internal function to calculate aggregated reputation
(define-private (calculate-reputation-internal (address principal))
  (let
    (
      (result (fold calculate-platform-score (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10)
                     { address: address, total-score: u0, weighted-score: u0, total-weight: u0, platform-count: u0 }))
    )
    {
      total-score: (get total-score result),
      weighted-score: (if (> (get total-weight result) u0)
                        (/ (* (get weighted-score result) u100) (get total-weight result))
                        u0),
      platform-count: (get platform-count result),
      total-weight: (get total-weight result)
    }
  )
)

;; Helper function for fold operation to calculate platform scores
(define-private (calculate-platform-score (platform-id uint) (acc { address: principal, total-score: uint, weighted-score: uint, total-weight: uint, platform-count: uint }))
  (match (map-get? platforms { platform-id: platform-id })
    platform-data
      (if (get is-active platform-data)
        (match (map-get? reputation-scores { address: (get address acc), platform-id: platform-id })
          score-data
            {
              address: (get address acc),
              total-score: (+ (get total-score acc) (get score score-data)),
              weighted-score: (+ (get weighted-score acc) (* (get score score-data) (get weight platform-data))),
              total-weight: (+ (get total-weight acc) (get weight platform-data)),
              platform-count: (+ (get platform-count acc) u1)
            }
          acc ;; No score found for this platform, return accumulator unchanged
        )
        acc ;; Platform not active, return accumulator unchanged
      )
    acc ;; Platform not found, return accumulator unchanged
  )
)
