"""
example/eth_usdt.py

Demonstrates swapping ETH -> USDT via Uniswap V3 (0.01% fee tier) using PrismRouter.
The output fee mode is used here: protocol fee is taken from the received USDT.

Setup:
    pip install web3 eth-abi
    export RPC_URL=https://mainnet.infura.io/v3/<YOUR_KEY>
    export ROUTER_ADDRESS=<deployed PrismRouter address>
    export ADAPTER_ADDRESS=<deployed PrismMainnetAdapter address>
    export CALLER=<your wallet address>
"""

import os
from web3 import Web3
import eth_abi
import json

# ── Configuration ─────────────────────────────────────────────────────────────
RPC_URL         = os.environ["RPC_URL"]
ROUTER_ADDRESS  = os.environ["ROUTER_ADDRESS"]
ADAPTER_ADDRESS = os.environ["ADAPTER_ADDRESS"]
CALLER          = os.environ["CALLER"]

with open("Router.json") as f:
    router_abi = json.load(f)["abi"]

web3   = Web3(Web3.HTTPProvider(RPC_URL))
router = web3.eth.contract(address=ROUTER_ADDRESS, abi=router_abi)

# ── Token addresses (Ethereum mainnet) ────────────────────────────────────────
ETH  = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
USDT = "0xdAC17F958D2ee523a2206206994597C13D831ec7"

# ── Swap parameters ───────────────────────────────────────────────────────────
from_amount  = web3.to_wei(1_000, "gwei")  # 0.000001 ETH
min_out      = 0                             # no slippage guard for gas estimation
fee_rate     = 0
fee_receiver = "0x0000000000000000000000000000000000000001"

E18 = 10 ** 18

# ── Build swapType=5 (Uniswap V3, 0.01% tier) step ──────────────────────────
# Using the WETH/USDT pool with 100 (0.01%) fee tier.
# UniswapV3Data: (router, sqrtX96=0, fee=100)
UNI_V3_ROUTER = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"  # Uniswap V3 SwapRouter02
step_data = eth_abi.abi.encode(
    ("address", "uint160", "uint24"),
    [UNI_V3_ROUTER, 0, 100],  # 100 = 0.01% fee tier
)

swap_step   = (E18, 5, step_data)               # swapType=5 -> Uniswap V3
dex_hop     = (ADAPTER_ADDRESS, E18, [swap_step])
hop_path    = (USDT, [dex_hop])
route_group = (E18, [hop_path])

# ── Gas estimate ──────────────────────────────────────────────────────────────
try:
    gas = router.functions.swap(
        ETH,
        from_amount,
        USDT,
        min_out,
        False,          # feeOnFromToken=False -> fee taken from USDT output
        fee_rate,
        fee_receiver,
        [route_group],
    ).estimate_gas({"from": CALLER, "value": from_amount})
    print(f"Estimated gas: {gas}")
except Exception as exc:
    print(f"Gas estimation failed: {exc}")