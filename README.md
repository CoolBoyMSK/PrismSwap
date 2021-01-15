# PrismSwap

A personal Solidity project implementing a production-grade on-chain token swap
system with two complementary components:

1. **PrismHub** - A meta-aggregator router that routes swaps through
   multiple third-party DEX aggregators (1inch, Paraswap, KyberSwap,
   Uniswap Universal Router, MachaV2, Magpie) via a flexible, pluggable
   adapter pattern.
2. **PrismRouter** - A self-built DEX aggregator that optimises swap routes
   by splitting orders across multiple DEXs in-house (Uniswap V2/V3/V4,
   Curve V1/V2, Balancer V1/V2, Velodrome, AlgebraV3, Maker PSM).

## Features

- Pluggable adapter pattern - add any external aggregator without changing core logic
- Split-order routing across multiple DEXs to minimise price impact
- Configurable fee collection on the input token or the output token
- Three-admin pause/unpause consensus mechanism for emergency stops
- Native ETH and any ERC20 token supported uniformly
- OpenZeppelin ReentrancyGuard on all external entry points
- Hard `minAmountOut` slippage enforcement on every swap

## Supported DEXs (PrismRouter)

| swapType | Protocol                                    |
|----------|---------------------------------------------|
| 1        | Uniswap V2 (and all V2-compatible forks)    |
| 2        | Maker PSM                                   |
| 3        | Curve V1                                    |
| 4        | Curve V2                                    |
| 5        | Uniswap V3                                  |
| 6        | Velodrome                                   |
| 7        | Balancer V1                                 |
| 8        | Balancer V2                                 |
| 9        | AlgebraV3                                   |
| 10       | Uniswap V3 forks (SushiSwap V3, PancakeV3)  |
| 11       | WETH wrap / unwrap                          |
| 12       | Uniswap V4                                  |

## Supported Aggregators (PrismHub)

- 1inch
- Paraswap
- KyberSwap
- Uniswap Universal Router
- MachaV2
- Magpie

## Getting Started

### Prerequisites

Install [Foundry](https://book.getfoundry.sh/).

### Install dependencies

```bash
cd prism-swap
forge install
```

### Run tests (requires an Ethereum mainnet fork RPC)

```bash
cd prism-swap
forge test -f <YOUR_ETH_MAINNET_RPC_URL> -vvv
```

### Build

```bash
forge build
```

### Deploy

```bash
forge script script/Deploy.s.sol --sig "deploy()" \
  --rpc-url <YOUR_RPC_URL> \
  --private-key <YOUR_PRIVATE_KEY> \
  --broadcast -vvvv
```

## Documentation

- [PrismRouter documentation](prism-swap/ROUTERREADME.md)
- [PrismHub documentation](prism-swap/DEXSWAPREADME.md)

## License

MIT
