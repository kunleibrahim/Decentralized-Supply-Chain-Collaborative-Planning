;; Entity Verification Contract
;; Validates and manages supply chain participants

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))

;; Entity types
(define-constant entity-supplier u1)
(define-constant entity-manufacturer u2)
(define-constant entity-distributor u3)
(define-constant entity-retailer u4)

;; Data structures
(define-map entities
  { entity-id: principal }
  {
    entity-type: uint,
    name: (string-ascii 50),
    verified: bool,
    registration-block: uint,
    reputation-score: uint
  }
)

(define-map entity-relationships
  { from-entity: principal, to-entity: principal }
  { relationship-type: uint, active: bool }
)

;; Public functions
(define-public (register-entity (entity-type uint) (name (string-ascii 50)))
  (let ((entity-id tx-sender))
    (asserts! (is-none (map-get? entities { entity-id: entity-id })) err-already-exists)
    (asserts! (and (>= entity-type u1) (<= entity-type u4)) (err u104))
    (map-set entities
      { entity-id: entity-id }
      {
        entity-type: entity-type,
        name: name,
        verified: false,
        registration-block: block-height,
        reputation-score: u50
      }
    )
    (ok entity-id)
  )
)

(define-public (verify-entity (entity-id principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (map-get? entities { entity-id: entity-id })
      entity-data (begin
        (map-set entities
          { entity-id: entity-id }
          (merge entity-data { verified: true })
        )
        (ok true)
      )
      err-not-found
    )
  )
)

(define-public (establish-relationship (to-entity principal) (relationship-type uint))
  (let ((from-entity tx-sender))
    (asserts! (is-some (map-get? entities { entity-id: from-entity })) err-not-found)
    (asserts! (is-some (map-get? entities { entity-id: to-entity })) err-not-found)
    (map-set entity-relationships
      { from-entity: from-entity, to-entity: to-entity }
      { relationship-type: relationship-type, active: true }
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-entity (entity-id principal))
  (map-get? entities { entity-id: entity-id })
)

(define-read-only (is-verified (entity-id principal))
  (match (map-get? entities { entity-id: entity-id })
    entity-data (get verified entity-data)
    false
  )
)

(define-read-only (get-relationship (from-entity principal) (to-entity principal))
  (map-get? entity-relationships { from-entity: from-entity, to-entity: to-entity })
)
