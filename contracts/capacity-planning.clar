;; Capacity Planning Contract
;; Aligns production capacity with demand forecasts

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-capacity (err u103))
(define-constant err-insufficient-capacity (err u104))

;; Data structures
(define-map production-capacity
  { entity-id: principal, resource-type: uint }
  {
    max-capacity: uint,
    current-utilization: uint,
    efficiency-rate: uint,
    maintenance-schedule: uint
  }
)

(define-map capacity-allocations
  { entity-id: principal, product-id: uint, period: uint }
  {
    allocated-capacity: uint,
    planned-output: uint,
    priority-level: uint,
    allocation-timestamp: uint
  }
)

(define-map resource-requirements
  { product-id: uint, resource-type: uint }
  { units-per-product: uint, processing-time: uint }
)

;; Public functions
(define-public (set-production-capacity (resource-type uint) (max-capacity uint) (efficiency-rate uint))
  (let ((entity-id tx-sender))
    (asserts! (> max-capacity u0) err-invalid-capacity)
    (asserts! (and (>= efficiency-rate u1) (<= efficiency-rate u100)) err-invalid-capacity)
    (map-set production-capacity
      { entity-id: entity-id, resource-type: resource-type }
      {
        max-capacity: max-capacity,
        current-utilization: u0,
        efficiency-rate: efficiency-rate,
        maintenance-schedule: u0
      }
    )
    (ok true)
  )
)

(define-public (allocate-capacity (product-id uint) (period uint) (allocated-capacity uint) (planned-output uint) (priority-level uint))
  (let ((entity-id tx-sender))
    (asserts! (> allocated-capacity u0) err-invalid-capacity)
    (asserts! (> planned-output u0) err-invalid-capacity)
    (asserts! (and (>= priority-level u1) (<= priority-level u5)) err-invalid-capacity)

    ;; Check if capacity is available (simplified check)
    (asserts! (check-capacity-availability entity-id allocated-capacity) err-insufficient-capacity)

    (map-set capacity-allocations
      { entity-id: entity-id, product-id: product-id, period: period }
      {
        allocated-capacity: allocated-capacity,
        planned-output: planned-output,
        priority-level: priority-level,
        allocation-timestamp: (unwrap-panic (get-block-info? time block-height))
      }
    )
    (ok true)
  )
)

(define-public (update-utilization (resource-type uint) (new-utilization uint))
  (let ((entity-id tx-sender))
    (match (map-get? production-capacity { entity-id: entity-id, resource-type: resource-type })
      capacity-data (begin
        (asserts! (<= new-utilization (get max-capacity capacity-data)) err-invalid-capacity)
        (map-set production-capacity
          { entity-id: entity-id, resource-type: resource-type }
          (merge capacity-data { current-utilization: new-utilization })
        )
        (ok true)
      )
      err-not-found
    )
  )
)

(define-public (set-resource-requirements (product-id uint) (resource-type uint) (units-per-product uint) (processing-time uint))
  (begin
    (map-set resource-requirements
      { product-id: product-id, resource-type: resource-type }
      { units-per-product: units-per-product, processing-time: processing-time }
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-production-capacity (entity-id principal) (resource-type uint))
  (map-get? production-capacity { entity-id: entity-id, resource-type: resource-type })
)

(define-read-only (get-capacity-allocation (entity-id principal) (product-id uint) (period uint))
  (map-get? capacity-allocations { entity-id: entity-id, product-id: product-id, period: period })
)

(define-read-only (get-resource-requirements (product-id uint) (resource-type uint))
  (map-get? resource-requirements { product-id: product-id, resource-type: resource-type })
)

(define-read-only (calculate-available-capacity (entity-id principal) (resource-type uint))
  (match (map-get? production-capacity { entity-id: entity-id, resource-type: resource-type })
    capacity-data (some (- (get max-capacity capacity-data) (get current-utilization capacity-data)))
    none
  )
)

;; Private functions
(define-private (check-capacity-availability (entity-id principal) (required-capacity uint))
  ;; Simplified capacity check - in reality would check across all resource types
  (match (calculate-available-capacity entity-id u1)
    available-capacity (>= available-capacity required-capacity)
    false
  )
)
