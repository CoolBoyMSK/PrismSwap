/**
 * addExecutor.js
 *
 * Registers a new DEX adapter on PrismRouter via the setDEXAdapter method.
 *
 * Usage:
 *   RPC_URL=<rpc> PRIVATE_KEY=<key> ROUTER_ADDRESS=<addr> \
 *   ADAPTER_ADDRESS=<addr> EXECUTOR_ADDRESS=<addr> node script/addExecutor.js
 *
 * Required environment variables:
 *   RPC_URL          - Ethereum JSON-RPC endpoint
 *   PRIVATE_KEY      - Sender private key (must be an admin of PrismRouter)
 *   ROUTER_ADDRESS   - Deployed PrismRouter contract address
 *   ADAPTER_ADDRESS  - Aggregator adapter contract to register
 *   EXECUTOR_ADDRESS - Executor contract to link with the adapter
 */

const { Web3 } = require('web3');

const RPC_URL        = process.env.RPC_URL;
const PRIVATE_KEY    = process.env.PRIVATE_KEY;
const ROUTER_ADDRESS = process.env.ROUTER_ADDRESS;
const ADAPTER_ADDRESS  = process.env.ADAPTER_ADDRESS;
const EXECUTOR_ADDRESS = process.env.EXECUTOR_ADDRESS;

if (!RPC_URL || !PRIVATE_KEY || !ROUTER_ADDRESS || !ADAPTER_ADDRESS || !EXECUTOR_ADDRESS) {
    console.error("Missing required environment variables. See usage comment at top of file.");
    process.exit(1);
}

const { abi } = require('../out/PrismRouter.sol/PrismRouter.json');

const web3 = new Web3(RPC_URL);
web3.eth.accounts.wallet.add(PRIVATE_KEY);
const sender = web3.eth.accounts.wallet[0].address;

async function registerAdapter() {
    const router = new web3.eth.Contract(abi, ROUTER_ADDRESS);
    try {
        const receipt = await router.methods
            .setDEXAdapter(ADAPTER_ADDRESS, EXECUTOR_ADDRESS, true)
            .send({ from: sender, gasPrice: "14000000000" });
        console.log("setDEXAdapter tx hash:", receipt.transactionHash);
    } catch (error) {
        console.error("Error calling setDEXAdapter:", error);
    }
}

registerAdapter();
