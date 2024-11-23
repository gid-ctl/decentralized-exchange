# Decentralized Exchange Smart Contract

A robust and secure smart contract implementation for a decentralized exchange (DEX) built on the Stacks blockchain. This contract enables atomic swaps between tokens using automated liquidity pools, following the constant product market maker model.

## Features

- **Automated Market Making**: Implements constant product market maker (CPMM) model
- **Liquidity Pools**: Support for creating and managing token pair liquidity pools
- **Atomic Swaps**: Direct token-to-token exchanges with guaranteed execution
- **Governance Controls**: Emergency shutdown and protocol management capabilities
- **Fee Mechanism**: Built-in protocol fee structure (0.3%)
- **Price Oracle Integration**: Support for external price feeds and cumulative price tracking
- **Slippage Protection**: Configurable minimum output for trades

## Technical Specifications

### Constants

- Protocol Fee: 0.3% (3/1000)
- Minimum Liquidity: 1000 units
- Precision: 6 decimal places (1,000,000)

### Error Codes

```clarity
ERR-NOT-AUTHORIZED (u100)
ERR-POOL-EXISTS (u101)
ERR-NO-POOL (u102)
ERR-INSUFFICIENT-LIQUIDITY (u103)
ERR-SLIPPAGE-TOO-HIGH (u104)
ERR-INVALID-PAIR (u105)
ERR-ZERO-AMOUNT (u106)
ERR-DEADLINE-PASSED (u107)
ERR-TRANSFER-FAILED (u108)
```

## Core Functions

### Pool Management

#### create-pool

Creates a new liquidity pool for a token pair.

```clarity
(define-public (create-pool (token-x principal) (token-y principal))
```

#### add-liquidity

Adds liquidity to an existing pool.

```clarity
(define-public (add-liquidity
    (token-x <ft-trait>)
    (token-y <ft-trait>)
    (amount-x uint)
    (amount-y uint)
    (min-shares uint)
    (deadline uint))
```

### Trading

#### swap-exact-tokens

Executes a token swap with exact input amount.

```clarity
(define-public (swap-exact-tokens
    (token-in <ft-trait>)
    (token-out <ft-trait>)
    (amount-in uint)
    (min-amount-out uint)
    (deadline uint))
```

### Read-Only Functions

- `get-pool-details`: Retrieves detailed information about a specific pool
- `get-reserves`: Gets current reserve amounts for a token pair
- `get-provider-shares`: Returns liquidity provider share information

### Governance Functions

- `set-emergency-shutdown`: Enables/disables emergency shutdown mode
- `set-governance-token`: Sets the contract's governance token

## Security Features

1. **Deadline Protection**: All transactions include a deadline parameter to prevent stale executions
2. **Slippage Controls**: Minimum output amounts can be specified for trades
3. **Emergency Shutdown**: Governance can pause trading in case of emergencies
4. **Access Controls**: Critical functions restricted to contract owner
5. **Integer Math**: Uses precise integer arithmetic to prevent rounding errors

## Price Calculation

The contract uses the constant product formula (x \* y = k) for price calculation:

- Swap amounts are calculated using: `amount_out = (input_amount * output_reserve) / (input_reserve + input_amount)`
- A 0.3% protocol fee is deducted from each trade
- Price impact is automatically calculated based on pool reserves

## Liquidity Provider Mechanics

- Initial liquidity providers receive shares based on the geometric mean of deposited amounts
- Subsequent providers receive shares proportional to their contribution relative to existing reserves
- Minimum liquidity requirement prevents manipulation of small pools

## Token Standard

The contract implements the SIP-010 fungible token standard trait, ensuring compatibility with all compliant tokens on the Stacks blockchain.

## Usage Examples

### Creating a Pool

```clarity
(contract-call? .decentralized-exchange create-pool token-x-principal token-y-principal)
```

### Adding Liquidity

```clarity
(contract-call? .decentralized-exchange add-liquidity
    token-x-contract
    token-y-contract
    u1000000
    u1000000
    u900000
    u100)
```

### Executing a Swap

```clarity
(contract-call? .decentralized-exchange swap-exact-tokens
    token-in-contract
    token-out-contract
    u1000000
    u950000
    u100)
```

## Development and Testing

The contract can be tested using the Clarinet console:

1. Install Clarinet
2. Run `clarinet console` in the project directory
3. Use the provided contract calls to interact with the DEX

## Security Considerations

1. **Frontrunning Protection**: Use appropriate slippage tolerances and deadlines
2. **Price Manipulation**: Large trades should be split to minimize price impact
3. **Pool Initialization**: Initial liquidity should be substantial to prevent manipulation
4. **Emergency Procedures**: Monitor for unusual activity and utilize emergency shutdown if needed
