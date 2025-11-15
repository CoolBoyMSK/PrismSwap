// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../Initial.t.sol";

contract Adapter1Test is PrismBaseTest {
    function testCurveV1WrongSwapType() public {
        CurveV1SwapArg memory arg = CurveV1SwapArg(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7, 0, 1, 0);
        PrismStructs.SwapStep[] memory swaps = new PrismStructs.SwapStep[](1);
        bytes memory payload = abi.encode(arg);
        PrismStructs.SwapStep memory simpleSwap = PrismStructs.SwapStep(1e18, 13, payload);
        swaps[0] = simpleSwap;
        PrismStructs.Adapter[] memory adapters = new PrismStructs.Adapter[](1);
        PrismStructs.Adapter memory adapter = PrismStructs.Adapter(payable(adapter1), 1e18, swaps);
        adapters[0] = adapter;
        PrismStructs.HopPath memory singlePath0 = PrismStructs.HopPath(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, adapters);
        PrismStructs.HopPath[] memory singlePaths = new PrismStructs.HopPath[](1);
        singlePaths[0] = singlePath0;
        PrismStructs.RouteGroup memory multiPath = PrismStructs.RouteGroup(1e18, singlePaths);
        PrismStructs.RouteGroup[] memory multiPaths = new PrismStructs.RouteGroup[](1);
        multiPaths[0] = multiPath;
        deal(0x6B175474E89094C44Da98b954EedeAC495271d0F, address(this), 100e18);
        IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F).approve(address(router), 100 ether);

        cheats.expectRevert("PrismExecutor: invalid swapType");
        router.swap(
            0x6B175474E89094C44Da98b954EedeAC495271d0F,
            100 ether,
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            99e6,
            false,
            0,
            feeReceiver,
            multiPaths
        );
    }

    function testCurveV1WrongAdapterPercentage() public {
        CurveV1SwapArg memory arg = CurveV1SwapArg(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7, 0, 1, 0);
        PrismStructs.SwapStep[] memory swaps = new PrismStructs.SwapStep[](1);
        bytes memory payload = abi.encode(arg);
        PrismStructs.SwapStep memory simpleSwap = PrismStructs.SwapStep(7e17, 3, payload);
        swaps[0] = simpleSwap;
        PrismStructs.Adapter[] memory adapters = new PrismStructs.Adapter[](1);
        PrismStructs.Adapter memory adapter = PrismStructs.Adapter(payable(adapter1), 1e18, swaps);
        adapters[0] = adapter;
        PrismStructs.HopPath memory singlePath0 = PrismStructs.HopPath(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, adapters);
        PrismStructs.HopPath[] memory singlePaths = new PrismStructs.HopPath[](1);
        singlePaths[0] = singlePath0;
        PrismStructs.RouteGroup memory multiPath = PrismStructs.RouteGroup(1e18, singlePaths);
        PrismStructs.RouteGroup[] memory multiPaths = new PrismStructs.RouteGroup[](1);
        multiPaths[0] = multiPath;
        deal(0x6B175474E89094C44Da98b954EedeAC495271d0F, address(this), 100e18);
        IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F).approve(address(router), 100 ether);

        cheats.expectRevert("Adapter: Invalid total percent");
        router.swap(
            0x6B175474E89094C44Da98b954EedeAC495271d0F,
            100 ether,
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            99e6,
            false,
            0,
            feeReceiver,
            multiPaths
        );
    }
}
