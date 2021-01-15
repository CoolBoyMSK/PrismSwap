"""
example/eth_pepe.py

Demonstrates swapping ETH -> PEPE via a Uniswap V2 pool using PrismRouter.
This script estimates gas only; it does NOT broadcast a transaction.

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
ETH  = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"  # sentinel for native ETH
PEPE = "0x6982508145454Ce325dDbE47a25d4ec3d2311933"

# ── Swap parameters ───────────────────────────────────────────────────────────
from_token_amount = web3.to_wei(1_000, "gwei")  # 0.000001 ETH
min_amount_out    = 10                            # minimum PEPE to accept
fee_rate          = 0                             # 0% protocol fee (base 1e18)
fee_receiver      = "0x0000000000000000000000000000000000000001"  # unused at fee_rate=0

E18 = 10 ** 18  # denominator for percent fields

# ── Build swapType=1 (Uniswap V2) step ───────────────────────────────────────
# pool    : WETH/PEPE Uniswap V2 pair
# fee     : 3   (numerator of 0.3% fee)
# denFee  : 1000 (denominator)
PEPE_ETH_V2_POOL = "0xA43fe16908251ee70EF74718545e4FE6C5cCEc9f"
step_data = eth_abi.abi.encode(
    ("address", "uint256", "uint256"),
    [PEPE_ETH_V2_POOL, 3, 1000],
)

swap_step   = (E18, 1, step_data)               # (percent, swapType=1 V2, data)
dex_hop     = (ADAPTER_ADDRESS, E18, [swap_step])  # (adapter, percent, steps)
hop_path    = (PEPE, [dex_hop])                 # (toToken, dexHops)
route_group = (E18, [hop_path])                 # (percent 100%, hopPaths)

# ── Gas estimate ──────────────────────────────────────────────────────────────
try:
    gas = router.functions.swap(
        ETH,
        from_token_amount,
        PEPE,
        min_amount_out,
        True,           # feeOnFromToken
        fee_rate,
        fee_receiver,
        [route_group],
    ).estimate_gas({"from": CALLER, "value": from_token_amount})
    print(f"Estimated gas: {gas}")
except Exception as exc:
    print(f"Gas estimation failed: {exc}")