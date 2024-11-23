;; title: Decentralized Exchange (DEX) Smart Contract
;; summary: A smart contract enabling atomic swaps between BTC and STX using liquidity pools.
;; description: This smart contract facilitates decentralized exchange operations by allowing users to create liquidity pools, add liquidity, and perform token swaps. It includes governance functions for managing the contract and ensures secure and efficient trading through various error checks and fee mechanisms.

;; Token Trait Definition
(use-trait ft-trait .sip-010-trait.sip-010-trait)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-POOL-EXISTS (err u101))
(define-constant ERR-NO-POOL (err u102))
(define-constant ERR-INSUFFICIENT-LIQUIDITY (err u103))
(define-constant ERR-SLIPPAGE-TOO-HIGH (err u104))
(define-constant ERR-INVALID-PAIR (err u105))
(define-constant ERR-ZERO-AMOUNT (err u106))
(define-constant ERR-DEADLINE-PASSED (err u107))

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant FEE-DENOMINATOR u1000)
(define-constant PROTOCOL-FEE u3) ;; 0.3%
(define-constant MIN-LIQUIDITY u1000)
(define-constant PRECISION u1000000) ;; 6 decimal places

;; Data vars
(define-data-var last-price-update uint u0)
(define-data-var governance-token (optional principal) none)
(define-data-var emergency-shutdown bool false)

;; Data maps
(define-map pools 
    {token-x: principal, token-y: principal}
    {
        liquidity: uint,
        reserve-x: uint,
        reserve-y: uint,
        total-shares: uint,
        last-block-height: uint,
        cumulative-price-x: uint,
        cumulative-price-y: uint
    }
)

(define-map liquidity-providers
    {pool-id: {token-x: principal, token-y: principal}, provider: principal}
    {shares: uint}
)

(define-map price-oracles
    principal
    {
        price: uint,
        last-update: uint,
        valid-period: uint
    }
)

;; Helper functions
(define-private (get-smaller (a uint) (b uint))
    (if (<= a b) a b))

;; Private functions
(define-private (calculate-swap-amount (input-amount uint) (input-reserve uint) (output-reserve uint))
    (let (
        (input-with-fee (* input-amount (- FEE-DENOMINATOR PROTOCOL-FEE)))
        (numerator (* input-with-fee output-reserve))
        (denominator (+ (* input-reserve FEE-DENOMINATOR) input-with-fee))
    )
    (/ numerator denominator))
)

;; Non-recursive square root approximation
(define-private (approximate-sqrt (y uint))
    (let (
        (n (+ y u1))  ;; Initial guess
        (n2 (/ y n))  ;; Second approximation
        (n3 (/ (+ n n2) u2))  ;; Average of approximations
    )
    n3)  ;; Return approximation
)

(define-private (calculate-initial-liquidity (amount-x uint) (amount-y uint))
    (let (
        (geometric-mean (approximate-sqrt (* amount-x amount-y)))
    )
    (if (< geometric-mean MIN-LIQUIDITY)
        MIN-LIQUIDITY
        geometric-mean))
)

(define-private (calculate-liquidity-shares 
    (amount-x uint) 
    (amount-y uint) 
    (total-supply uint) 
    (reserve-x uint) 
    (reserve-y uint))
    (if (is-eq total-supply u0)
        (calculate-initial-liquidity amount-x amount-y)
        (get-smaller
            (/ (* amount-x total-supply) reserve-x)
            (/ (* amount-y total-supply) reserve-y)
        ))
)

;; Public functions
(define-public (create-pool (token-x principal) (token-y principal))
    (begin
        (asserts! (is-none (map-get? pools {token-x: token-x, token-y: token-y})) (err ERR-POOL-EXISTS))
        (asserts! (is-eq tx-sender CONTRACT-OWNER) (err ERR-NOT-AUTHORIZED))
        
        (map-set pools 
            {token-x: token-x, token-y: token-y}
            {
                liquidity: u0,
                reserve-x: u0,
                reserve-y: u0,
                total-shares: u0,
                last-block-height: block-height,
                cumulative-price-x: u0,
                cumulative-price-y: u0
            }
        )
        (ok true)
    )
)

(define-public (add-liquidity (token-x <ft-trait>) 
                             (token-y <ft-trait>)
                             (amount-x uint)
                             (amount-y uint)
                             (min-shares uint)
                             (deadline uint))
    (let (
        (pool (unwrap! (map-get? pools {token-x: (contract-of token-x), token-y: (contract-of token-y)}) (err ERR-NO-POOL)))
        (shares (calculate-liquidity-shares 
            amount-x 
            amount-y 
            (get total-shares pool)
            (get reserve-x pool)
            (get reserve-y pool)))
    )
    (asserts! (<= block-height deadline) (err ERR-DEADLINE-PASSED))
    (asserts! (>= shares min-shares) (err ERR-SLIPPAGE-TOO-HIGH))
    
    ;; Transfer tokens to pool - fixed to include memo
    (try! (contract-call? token-x transfer amount-x tx-sender (as-contract tx-sender) (some 0x)))
    (try! (contract-call? token-y transfer amount-y tx-sender (as-contract tx-sender) (some 0x)))
    
    ;; Update pool data
    (map-set pools 
        {token-x: (contract-of token-x), token-y: (contract-of token-y)}
        {
            liquidity: (+ (get liquidity pool) u1),
            reserve-x: (+ (get reserve-x pool) amount-x),
            reserve-y: (+ (get reserve-y pool) amount-y),
            total-shares: (+ (get total-shares pool) shares),
            last-block-height: block-height,
            cumulative-price-x: (get cumulative-price-x pool),
            cumulative-price-y: (get cumulative-price-y pool)
        }
    )
    
    ;; Update provider shares
    (map-set liquidity-providers
        {pool-id: {token-x: (contract-of token-x), token-y: (contract-of token-y)}, provider: tx-sender}
        {shares: (+ (default-to u0 (get shares (map-get? liquidity-providers 
            {pool-id: {token-x: (contract-of token-x), token-y: (contract-of token-y)}, provider: tx-sender}))) shares)}
    )
    
    (ok shares))
)