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