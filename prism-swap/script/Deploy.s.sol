// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {PrismRouter}    from "../src/router/PrismRouter.sol";
import {PrismMainnetAdapter} from "../src/adapter/mainnet/PrismMainnetAdapter.sol";

/**
 * @title Deploy
 * @notice Deployment script for PrismRouter + PrismMainnetAdapter (Ethereum mainnet)
 *
 * Usage:
 *   forge script script/Deploy.s.sol --sig "deploy()" \
 *     --rpc-url <RPC_URL> \
 *     --private-key <PRIVATE_KEY> \
 *     --broadcast -vvvv
 */
contract Deploy is Script {
    // Excluded from coverage
    function test() public {}

    modifier broadcast() {
        vm.startBroadcast(msg.sender);
        _;
        vm.stopBroadcast();
    }

    // ── Well-known Ethereum mainnet addresses ────────────────────────────────
    address constant WETH    = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant DAI     = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    /// @notice Max protocol fee: 0.875% expressed in 1e18 base
    uint256 constant MAX_FEE_RATE = 8.75e15;

    function deployPrismRouter(address[3] memory admins)
        public
        broadcast
        returns (address addr)
    {
        console.log("Deploying PrismRouter...");
        PrismRouter router = new PrismRouter(admins, MAX_FEE_RATE);
        addr = address(router);
        console.log("PrismRouter:", addr);
    }

    function deployPrismMainnetAdapter()
        public
        broadcast
        returns (address addr)
    {
        console.log("Deploying PrismMainnetAdapter...");
        PrismMainnetAdapter adapter = new PrismMainnetAdapter(DAI, WETH, PERMIT2);
        addr = address(adapter);
        console.log("PrismMainnetAdapter:", addr);
    }

    function registerAdapter(address router, address adapter)
        public
        broadcast
    {
        console.log("Registering PrismMainnetAdapter on PrismRouter...");
        PrismRouter(payable(router)).setDEXAdapter(adapter, true);
    }

    /**
     * @notice Full deploy: PrismRouter + PrismMainnetAdapter + registration.
     *   Replace admin[1] and admin[2] with your own addresses before running.
     */
    function deploy() public {
        address deployer = msg.sender;

        address[3] memory admins = [
            deployer,   // admin 0 — deployer
            address(0), // admin 1 — set your second multisig/EOA here
            address(0)  // admin 2 — set your third multisig/EOA here
        ];

        address router  = deployPrismRouter(admins);
        address adapter = deployPrismMainnetAdapter();
        registerAdapter(router, adapter);

        console.log("=== Deployment complete ===");
        console.log("PrismRouter   :", router);
        console.log("PrismMainnetAdapter:", adapter);
    }
}
