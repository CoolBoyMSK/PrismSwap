# Examples

Python scripts demonstrating how to build swap calldata for PrismRouter.

## Setup

1. Build the contracts to generate the ABI:
   ```bash
   cd .. && forge build
   ```
2. Copy the compiled artifact to this directory:
   ```bash
   cp ../out/PrismRouter.sol/PrismRouter.json Router.json
   ```
3. Install Python dependencies:
   ```bash
   pip install web3 eth-abi
   ```
4. Set environment variables:
   ```bash
   export RPC_URL=https://mainnet.infura.io/v3/<YOUR_KEY>
   export ROUTER_ADDRESS=<deployed PrismRouter address>
   export ADAPTER_ADDRESS=<deployed PrismMainnetAdapter address>
   export CALLER=<your wallet address>
   ```
5. Run an example:
   ```bash
   python3 eth_pepe.py
   ```

## Scripts

| Script | Description |
|---|---|
| `eth_pepe.py` | Swap ETH -> PEPE via Uniswap V2 (swapType=1) |
| `eth_pepe_uni3.py` | Swap ETH -> PEPE via Uniswap V3 (swapType=5) |
| `eth_usdt.py` | Swap ETH -> USDT via Uniswap V3 0.01% tier (swapType=5) |
