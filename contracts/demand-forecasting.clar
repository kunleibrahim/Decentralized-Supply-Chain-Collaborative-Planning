;; Demand Forecasting Contract
;; Predicts future requirements based on historical data

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-data (err u103))

;; Data structures
(define-map demand-history
  { entity-id: principal, product-id: uint, period: uint }
  { quantity: uint, timestamp: uint }
)

(define-map demand-forecasts
  { entity-id: principal, product-id: uint, forecast-period: uint }
  {
    predicted-quantity: uint,
    confidence-level: uint,
    created-at: uint,
    forecaster: principal
  }
)

(define-map product-info
  { product-id: uint }
  {
    name: (string-ascii 50),
    category: (string-ascii 30),
    seasonality-factor: uint
  }
)

;; Public functions
(define-public (record-demand (product-id uint) (quantity uint) (period uint))
  (let ((entity-id tx-sender))
    (asserts! (> quantity u0) err-invalid-data)
    (map-set demand-history
      { entity-id: entity-id, product-id: product-id, period: period }
      { quantity: quantity, timestamp: (unwrap-panic (get-block-info? time block-height)) }
    )
    (ok true)
  )
)

(define-public (create-forecast (entity-id principal) (product-id uint) (forecast-period uint) (predicted-quantity uint) (confidence-level uint))
  (begin
    (asserts! (and (>= confidence-level u1) (<= confidence-level u100)) err-invalid-data)
    (asserts! (> predicted-quantity u0) err-invalid-data)
    (map-set demand-forecasts
      { entity-id: entity-id, product-id: product-id, forecast-period: forecast-period }
      {
        predicted-quantity: predicted-quantity,
        confidence-level: confidence-level,
        created-at: (unwrap-panic (get-block-info? time block-height)),
        forecaster: tx-sender
      }
    )
    (ok true)
  )
)

(define-public (register-product (product-id uint) (name (string-ascii 50)) (category (string-ascii 30)) (seasonality-factor uint))
  (begin
    (asserts! (is-none (map-get? product-info { product-id: product-id })) (err u104))
    (map-set product-info
      { product-id: product-id }
      {
        name: name,
        category: category,
        seasonality-factor: seasonality-factor
      }
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-demand-history (entity-id principal) (product-id uint) (period uint))
  (map-get? demand-history { entity-id: entity-id, product-id: product-id, period: period })
)

(define-read-only (get-forecast (entity-id principal) (product-id uint) (forecast-period uint))
  (map-get? demand-forecasts { entity-id: entity-id, product-id: product-id, forecast-period: forecast-period })
)

(define-read-only (get-product-info (product-id uint))
  (map-get? product-info { product-id: product-id })
)

(define-read-only (calculate-trend (entity-id principal) (product-id uint) (periods uint))
  ;; Simple trend calculation based on recent periods
  (let ((recent-demand (default-to u0 (get quantity (get-demand-history entity-id product-id (- periods u1))))))
    (if (> recent-demand u0)
      (some recent-demand)
      none
    )
  )
)
