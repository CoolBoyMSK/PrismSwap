// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../Initial.t.sol";

contract BalancerV1ExecutorTest is PrismBaseTest {
    using SafeERC20 for IERC20;

    function testBalancerV1USDCToAMPL() public {
        bytes memory payload = abi.encode(0x7860E28ebFB8Ae052Bfe279c07aC5d94c9cD2937);
        PrismStructs.SwapStep[] memory swaps = new PrismStructs.SwapStep[](1);
        PrismStructs.SwapStep memory simpleSwap = PrismStructs.SwapStep(1e18, 7, payload);
        swaps[0] = simpleSwap;
        PrismStructs.Adapter[] memory adapters = new PrismStructs.Adapter[](1);
        PrismStructs.Adapter memory adapter = PrismStructs.Adapter(payable(adapter1), 1e18, swaps);
        adapters[0] = adapter;
        PrismStructs.HopPath memory singlePath0 = PrismStructs.HopPath(0xD46bA6D942050d489DBd938a2C909A5d5039A161, adapters);
        PrismStructs.HopPath[] memory singlePaths = new PrismStructs.HopPath[](1);
        singlePaths[0] = singlePath0;
        PrismStructs.RouteGroup memory multiPath = PrismStructs.RouteGroup(1e18, singlePaths);
        PrismStructs.RouteGroup[] memory multiPaths = new PrismStructs.RouteGroup[](1);
        multiPaths[0] = multiPath;

        deal(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, address(this), 100e6);
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).forceApprove(address(router), 100e6);
        uint256 amplBalanceBefore = IERC20(0xD46bA6D942050d489DBd938a2C909A5d5039A161).balanceOf(address(this));
        console.log("amplBalanceBefore: ", amplBalanceBefore);
        router.swap(
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            100e6,
            0xD46bA6D942050d489DBd938a2C909A5d5039A161,
            99e6,
            false,
            0,
            feeReceiver,
            multiPaths
        );
        uint256 amplBalanceAfter = IERC20(0xD46bA6D942050d489DBd938a2C909A5d5039A161).balanceOf(address(this));
        uint256 usdcBalanceAfter = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).balanceOf(address(this));
        console.log("amplBalanceAfter: ", amplBalanceAfter);
        console.log("usdcBalanceAfter: ", usdcBalanceAfter);
        assertEq(usdcBalanceAfter, 0);
    }
}
