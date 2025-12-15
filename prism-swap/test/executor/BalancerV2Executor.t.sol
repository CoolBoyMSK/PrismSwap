// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../Initial.t.sol";

contract BalancerV2ExecutorTest is PrismBaseTest {
    using SafeERC20 for IERC20;

    function testBalancerV2WethToCow() public {
        BalancerV2Param memory arg = BalancerV2Param(
            0xde8c195aa41c11a0c4787372defbbddaa31306d2000200000000000000000181,
            0xBA12222222228d8Ba445958a75a0704d566BF2C8
        );
        bytes memory payload = abi.encode(arg);
        PrismStructs.SwapStep[] memory swaps = new PrismStructs.SwapStep[](1);
        PrismStructs.SwapStep memory simpleSwap = PrismStructs.SwapStep(1e18, 8, payload);
        swaps[0] = simpleSwap;
        PrismStructs.Adapter[] memory adapters = new PrismStructs.Adapter[](1);
        PrismStructs.Adapter memory adapter = PrismStructs.Adapter(payable(adapter1), 1e18, swaps);
        adapters[0] = adapter;
        PrismStructs.HopPath memory singlePath0 = PrismStructs.HopPath(0xDEf1CA1fb7FBcDC777520aa7f396b4E015F497aB, adapters);
        PrismStructs.HopPath[] memory singlePaths = new PrismStructs.HopPath[](1);
        singlePaths[0] = singlePath0;
        PrismStructs.RouteGroup memory multiPath = PrismStructs.RouteGroup(1e18, singlePaths);
        PrismStructs.RouteGroup[] memory multiPaths = new PrismStructs.RouteGroup[](1);
        multiPaths[0] = multiPath;

        deal(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, address(this), 5e17);
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).forceApprove(address(router), 5e17);
        uint256 cowBalanceBefore = IERC20(0xDEf1CA1fb7FBcDC777520aa7f396b4E015F497aB).balanceOf(address(this));
        console.log("cowBalanceBefore: ", cowBalanceBefore);
        router.swap(
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            5e17,
            0xDEf1CA1fb7FBcDC777520aa7f396b4E015F497aB,
            2000e18,
            false,
            0,
            feeReceiver,
            multiPaths
        );
        uint256 cowBalanceAfter = IERC20(0xDEf1CA1fb7FBcDC777520aa7f396b4E015F497aB).balanceOf(address(this));
        uint256 ethBalanceAfter = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).balanceOf(address(this));
        console.log("cowBalanceAfter: ", cowBalanceAfter);
        console.log("ethBalanceAfter: ", ethBalanceAfter);
        assertEq(ethBalanceAfter, 0);
    }
}
