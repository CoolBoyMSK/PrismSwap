"""
example/eth_pepe_uni3.py

Demonstrates swapping ETH -> PEPE via a Uniswap V3 pool using PrismRouter.
Difference from eth_pepe.py: uses swapType=5 (Uniswap V3) instead of swapType=1.

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
PEPE = "0x6982508145454Ce325dDbE47a25d4ec3d2311933"

# ── Swap parameters ───────────────────────────────────────────────────────────
from_amount  = 10 ** 18           # 1 ETH
min_out      = 10
fee_rate     = 0
fee_receiver = "0x0000000000000000000000000000000000000001"

E18 = 10 ** 18

# ── Build swapType=5 (Uniswap V3) step ───────────────────────────────────────
# UniswapV3Data: (address router, uint160 sqrtX96, uint24 fee)
# sqrtX96=0  -> no price limit
# fee=3000   -> 0.3% fee tier
UNI_V3_ROUTER = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"  # Uniswap V3 SwapRouter02
step_data = eth_abi.abi.encode(
    ("address", "uint160", "uint24"),
    [UNI_V3_ROUTER, 0, 3000],
)

swap_step   = (E18, 5, step_data)               # swapType=5 -> Uniswap V3
dex_hop     = (ADAPTER_ADDRESS, E18, [swap_step])
hop_path    = (PEPE, [dex_hop])
route_group = (E18, [hop_path])

# ── Gas estimate ──────────────────────────────────────────────────────────────
try:
    gas = router.functions.swap(
        ETH, from_amount, PEPE, min_out, True, fee_rate, fee_receiver, [route_group]
    ).estimate_gas({"from": CALLER, "value": from_amount})
    print(f"Estimated gas: {gas}")
except Exception as exc:
    print(f"Gas estimation failed: {exc}")