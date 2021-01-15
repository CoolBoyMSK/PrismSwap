# PrismRouter - In-house DEX Aggregator

PrismRouter is a self-built DEX aggregator smart contract that finds and
executes optimal token swap routes across multiple decentralised exchanges.
It is designed to plug into PrismHub as one of its supported providers,
but can also be used as a standalone swap router.

## Introduction

PrismRouter optimises on-chain trading by splitting large orders across
multiple DEX pools simultaneously, reducing price impact and slippage for
the end user.

## Key Features

- **Smart Route Optimisation** - finds the most efficient multi-hop paths
- **Order Splitting** - divides a single trade across multiple DEXs by percentage
- **Slippage Protection** - hard `minAmountOut` check enforced on-chain
- **Multi-DEX Support** - Uniswap V2/V3/V4, Curve V1/V2, Balancer V1/V2,
  Velodrome, AlgebraV3, Maker PSM, WETH wrap/unwrap

## Architecture

| Component | Contract | Description |
|-----------|----------|-------------|
| Entry point | `PrismRouter` | Accepts swap params, charges fee, delegates to executor |
| Execution engine | `PrismExecutor` | Splits funds and delegates to adapters |
| DEX adapter bundle | `MainnetDEXAdapter` | Implements each DEX swap type |
| Admin control | `PrismAdmin` | Three-admin pause/unpause governance |

## How It Works

1. Caller submits `swap(fromToken, amount, toToken, minOut, paths...)`
2. `PrismRouter` optionally deducts the protocol fee from `fromToken`
3. Funds are transferred to `PrismExecutor`
4. `PrismExecutor` splits funds across `RouteGroup` entries by `percent`
5. Each path delegates to `MainnetDEXAdapter` via `delegatecall`
6. Adapter executes each `SwapStep` against the appropriate DEX pool
7. Resulting `toToken` balance is sent back to `PrismRouter`
8. `PrismRouter` enforces `minAmountOut`, optionally charges output fee,
   then transfers tokens to the caller

## Entry Point Parameters

All ETH swaps are converted to WETH internally.

```solidity
// RouteGroup represents a swap from A->B->C->D through multiple HopPaths
struct RouteGroup {
    uint256 percent;  // fraction of total input (base 1e18)
    HopPath[] paths;
}

// HopPath represents one A->B hop, optionally split across DEXs
struct HopPath {
    address toToken;
    DEXHop[] adapters;
}

struct DEXHop {
    address payable adapter;
    uint256 percent;    // fraction of this hop's input (base 1e18)
    SwapStep[] swaps;
}

// SwapStep is a single A->B operation on one pool
struct SwapStep {
    uint256 percent;   // fraction of this DEXHop's input (base 1e18)
    uint256 swapType;  // DEX identifier (1-12)
    bytes data;        // ABI-encoded pool parameters
}

function swap(
    address fromToken,
    uint256 fromTokenAmount,
    address toToken,
    uint256 minAmountOut,
    bool feeOnFromToken,
    uint256 feeRate,
    address feeReceiver,
    RouteGroup[] calldata paths
) external payable;
```

## SwapStep Construction

### swapType 1 - Uniswap V2

```solidity
struct UniswapV2SwapArg {
    address pool;
    uint256 fee;       // e.g. 3 for standard 0.3%
    uint256 denFee;    // e.g. 1000
}
bytes data = abi.encode(arg);
```

### swapType 5 - Uniswap V3

```solidity
struct UniswapV3Data {
    address router;
    uint160 sqrtX96;  // 0 = no price limit
    uint24 fee;       // e.g. 500, 3000, 10000
}
bytes data = abi.encode(arg);
```

### swapType 9 - AlgebraV3

```solidity
struct AlgebraV3Data {
    address router;
    uint160 sqrtX96;
}
bytes data = abi.encode(arg);
```

### swapType 6 - Velodrome

```solidity
struct VelodromeData {
    address router;
    uint160 sqrtX96;
    int24 tickSpacing;
}
bytes data = abi.encode(arg);
```

### swapType 3/4 - Curve V1/V2

```solidity
struct CurveV1SwapArg {
    address pool;
    int128 i;
    int128 j;
    uint8 curveV1SwapType; // 0=exchange, 1=exchange_underlying, 2=remove_liquidity_one_coin
}
bytes data = abi.encode(arg);
```

### swapType 7 - Balancer V1

```solidity
bytes data = abi.encode(poolAddress);
```

### swapType 8 - Balancer V2

```solidity
struct BalancerV2Data {
    address vault;
    bytes32 poolId;
}
bytes data = abi.encode(arg);
```

### swapType 11 - WETH wrap/unwrap

No `data` needed. PrismRouter detects direction from token addresses.

## Testing

```bash
forge test -f <YOUR_ETH_MAINNET_RPC_URL> -vvv
```

## Deployment

```bash
forge script script/Deploy.s.sol --sig "deploy()" \
  --rpc-url <YOUR_RPC_URL> \
  --private-key <YOUR_PRIVATE_KEY> \
  --broadcast -vvvv
```
