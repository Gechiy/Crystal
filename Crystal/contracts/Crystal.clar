;; CrystalGardens - Ethereal Flora Exchange Contract
;; Description: Contract for cultivating, trading, and exchanging ethereal flora known as "Crystal Blooms".

;; Error codes
(define-constant unauthorized-access (err u100))
(define-constant not-guardian (err u101))
(define-constant trade-not-active (err u102))
(define-constant offer-below-minimum (err u103))
(define-constant specimen-not-found (err u104))
(define-constant essence-corrupted (err u105))
(define-constant tithe-too-high (err u106))
(define-constant void-principal (err u107))

;; NFT asset
(define-non-fungible-token crystal-bloom uint)

;; Global vars
(define-data-var sanctuary-guardian principal tx-sender)
(define-data-var bloom-registry uint u1)

;; Data maps
(define-map flora-collection
  { specimen-id: uint }
  { guardian: principal, cultivator: principal, essence: (string-ascii 256), tithe: uint })

(define-map trading-post
  { specimen-id: uint }
  { exchange-value: uint, trader: principal })

;; Auth check
(define-private (validate-guardian)
  (is-eq tx-sender (var-get sanctuary-guardian)))

;; Principal check
(define-private (check-valid-entity (entity principal))
  (not (is-eq entity 'SP000000000000000000002Q6VF78)))

;; Reassign guardian
(define-public (anoint-guardian (new-guardian principal))
  (begin
    (asserts! (validate-guardian) unauthorized-access)
    (asserts! (check-valid-entity new-guardian) void-principal)
    (ok (var-set sanctuary-guardian new-guardian))
  ))

;; Query guardian
(define-read-only (current-guardian)
  (ok (var-get sanctuary-guardian)))

;; Cultivate bloom
(define-public (cultivate (essence (string-ascii 256)) (tithe uint))
  (let ((specimen-id (var-get bloom-registry)))
    (asserts! (> (len essence) u0) essence-corrupted)
    (asserts! (<= tithe u1000) tithe-too-high)
    (try! (nft-mint? crystal-bloom specimen-id tx-sender))
    (map-set flora-collection
      { specimen-id: specimen-id }
      { guardian: tx-sender, cultivator: tx-sender, essence: essence, tithe: tithe }
    )
    (var-set bloom-registry (+ specimen-id u1))
    (ok specimen-id)
  ))

;; Open trade
(define-public (open-trade (specimen-id uint) (exchange-value uint))
  (let ((current-guardian (unwrap! (nft-get-owner? crystal-bloom specimen-id) specimen-not-found)))
    (asserts! (> exchange-value u0) offer-below-minimum)
    (asserts! (is-eq tx-sender current-guardian) not-guardian)
    (map-set trading-post
      { specimen-id: specimen-id }
      { exchange-value: exchange-value, trader: tx-sender }
    )
    (ok true)
  ))

;; Close trade
(define-public (close-trade (specimen-id uint))
  (let ((trade-data (unwrap! (map-get? trading-post { specimen-id: specimen-id }) trade-not-active)))
    (asserts! (< specimen-id (var-get bloom-registry)) specimen-not-found)
    (asserts! (is-eq tx-sender (get trader trade-data)) not-guardian)
    (map-delete trading-post { specimen-id: specimen-id })
    (ok true)
  ))

;; Exchange bloom
(define-public (exchange (specimen-id uint))
  (let
    (
      (trade-data (unwrap! (map-get? trading-post { specimen-id: specimen-id }) trade-not-active))
      (exchange-sum (get exchange-value trade-data))
      (previous-trader (get trader trade-data))
      (bloom-data (unwrap! (map-get? flora-collection { specimen-id: specimen-id }) specimen-not-found))
      (first-cultivator (get cultivator bloom-data))
      (tithe-percent (get tithe bloom-data))
      (cultivator-tithe (/ (* exchange-sum tithe-percent) u10000))
      (trader-share (- exchange-sum cultivator-tithe))
    )
    (asserts! (< specimen-id (var-get bloom-registry)) specimen-not-found)
    (try! (stx-transfer? cultivator-tithe tx-sender first-cultivator))
    (try! (stx-transfer? trader-share tx-sender previous-trader))
    (try! (nft-transfer? crystal-bloom specimen-id previous-trader tx-sender))
    (map-set flora-collection
      { specimen-id: specimen-id }
      (merge bloom-data { guardian: tx-sender })
    )
    (map-delete trading-post { specimen-id: specimen-id })
    (ok true)
  ))

;; Inspect bloom
(define-read-only (observe (specimen-id uint))
  (ok (unwrap! (map-get? flora-collection { specimen-id: specimen-id }) specimen-not-found)))

;; Inspect trade
(define-read-only (observe-trade (specimen-id uint))
  (ok (unwrap! (map-get? trading-post { specimen-id: specimen-id }) trade-not-active)))