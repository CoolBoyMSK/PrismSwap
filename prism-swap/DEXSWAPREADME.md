# PrismHub - Multi-Aggregator Swap Router

Source: `src/swapHub/`

## Overview

PrismHub is a DEX meta-router that routes token swaps through multiple
external aggregators. It uses a pluggable adapter pattern so that new
aggregator integrations can be added or removed by admins without touching
the core routing logic.

## Key Features

- **Multi-Aggregator Support** - each aggregator is registered as a named adapter
- **Fee Management** - configurable fee charged on either the input or output token
- **ETH + ERC20** - handles both native ETH and any ERC20 token
- **Security** - ReentrancyGuard, pause mechanism, slippage protection

## Core Components

### PrismHub Contract

The main entry point. Handles:
- Swap execution via the registered adapter
- Fee calculation and collection
- Adapter lifecycle management (register/remove)

### PrismProxy Contract

A dedicated proxy that `delegatecall`s into the selected adapter. Separates
approval and execution state from the hub logic.

### Adapter Pattern

Each aggregator (1inch, Paraswap, KyberSwap, etc.) has its own adapter
contract that implements a standardised `swapOnAdapter` interface.

All adapters:
- Approve the aggregator's spender for the input token
- Forward calldata to the aggregator's router
- Return leftover input tokens to the caller
- Forward received output tokens back to `PrismHub`

## Registered Adapters

| ID         | Aggregator               |
|------------|--------------------------|
| `1inch`    | 1inch v6                 |
| `uni`      | Uniswap Universal Router |
| `paraswap` | Paraswap v6              |
| `kyber`    | KyberSwap                |
| `macha`    | MachaV2                  |
| `magpie`   | Magpie v3                |

## Swap Parameters

```solidity
struct TradeParams {
    string providerId;         // registered adapter key e.g. "1inch"
    address fromToken;
    uint256 fromTokenAmount;
    address toToken;
    uint256 minAmountOut;
    uint256 feeRate;           // fee fraction (base 1e18)
    bool feeOnFromToken;       // true = fee from input, false = fee from output
    address feeReceiver;
    bytes data;                // aggregator-specific calldata
}
```

## Swap Flow

1. Validate parameters and look up adapter
2. Deduct input fee (if `feeOnFromToken == true`)
3. Transfer `fromToken` to `PrismProxy`
4. `PrismProxy` delegates to the adapter contract
5. Adapter calls the external aggregator router
6. Output tokens returned to `PrismHub`
7. Verify `receivedAmount >= minAmountOut`
8. Deduct output fee (if `feeOnFromToken == false`)
9. Transfer final amount to caller

## Admin Functions

```solidity
function registerProvider(string calldata providerId, address addr, bytes4 selector) external onlyAdmin;
function unregisterProvider(string calldata providerId) external onlyAdmin;
function getProviders() external view returns (address[] memory);
```

## Testing

```bash
forge test -f <YOUR_ETH_MAINNET_RPC_URL> -vvv
```
