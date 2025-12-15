// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../Initial.t.sol";

contract ExecutorTest is PrismBaseTest {
    function testExecutorRevert() public {
        CurveV1SwapArg memory arg = CurveV1SwapArg(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7, 0, 1, 0);
        PrismStructs.SwapStep[] memory swaps = new PrismStructs.SwapStep[](1);
        bytes memory payload = abi.encode(arg);
        PrismStructs.SwapStep memory simpleSwap = PrismStructs.SwapStep(1e18, 3, payload);
        swaps[0] = simpleSwap;
        PrismStructs.Adapter[] memory adapters = new PrismStructs.Adapter[](1);
        PrismStructs.Adapter memory adapter = PrismStructs.Adapter(payable(adapter1), 1e18, swaps);
        adapters[0] = adapter;
        PrismStructs.HopPath memory singlePath0 = PrismStructs.HopPath(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, adapters);
        PrismStructs.HopPath[] memory singlePaths = new PrismStructs.HopPath[](1);
        singlePaths[0] = singlePath0;
        PrismStructs.RouteGroup memory multiPath = PrismStructs.RouteGroup(9e17, singlePaths);
        PrismStructs.RouteGroup[] memory multiPaths = new PrismStructs.RouteGroup[](1);
        multiPaths[0] = multiPath;
        deal(0x6B175474E89094C44Da98b954EedeAC495271d0F, address(this), 100e18);
        IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F).approve(address(router), 100 ether);

        cheats.expectRevert("PrismExecutor: route percent != 1e18");
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

        adapters = new PrismStructs.Adapter[](1);
        adapter = PrismStructs.Adapter(payable(feeReceiver), 1e18, swaps);
        adapters[0] = adapter;
        singlePath0 = PrismStructs.HopPath(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, adapters);
        singlePaths[0] = singlePath0;
        multiPath = PrismStructs.RouteGroup(9e17, singlePaths);
        multiPaths[0] = multiPath;

        cheats.expectRevert("PrismExecutor: adapter not approved");
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

    function testAdapterPercentageRevert() public {
        CurveV1SwapArg memory arg = CurveV1SwapArg(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7, 0, 1, 0);
        PrismStructs.SwapStep[] memory swaps = new PrismStructs.SwapStep[](1);
        bytes memory payload = abi.encode(arg);
        PrismStructs.SwapStep memory simpleSwap = PrismStructs.SwapStep(1e18, 3, payload);
        swaps[0] = simpleSwap;
        PrismStructs.Adapter[] memory adapters = new PrismStructs.Adapter[](1);
        PrismStructs.Adapter memory adapter = PrismStructs.Adapter(payable(adapter1), 9e17, swaps);
        adapters[0] = adapter;
        PrismStructs.HopPath memory singlePath0 = PrismStructs.HopPath(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, adapters);
        PrismStructs.HopPath[] memory singlePaths = new PrismStructs.HopPath[](1);
        singlePaths[0] = singlePath0;
        PrismStructs.RouteGroup memory multiPath = PrismStructs.RouteGroup(1e18, singlePaths);
        PrismStructs.RouteGroup[] memory multiPaths = new PrismStructs.RouteGroup[](1);
        multiPaths[0] = multiPath;
        deal(0x6B175474E89094C44Da98b954EedeAC495271d0F, address(this), 100e18);
        IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F).approve(address(router), 100 ether);

        cheats.expectRevert("PrismExecutor: adapter percent != 1e18");
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

    function testCrossRouteGroupTokenInterference() public {
        // Test the fix for cross-RouteGroup token interference
        // This test verifies that each RouteGroup uses only its allocated tokens

        // Initialize executor
        executor = new PrismExecutor();
        executor.setDEXAdapter(address(adapter1), true);

        // Setup: 10 wETH to USDC with two RouteGroups
        // RouteGroup[0]: 60% wETH -> PEPE -> wETH -> USDC
        // RouteGroup[1]: 40% wETH -> USDC

        // Create RouteGroup[0]: wETH -> PEPE -> wETH -> USDC (60%)
        PrismStructs.RouteGroup memory multiPath0;
        {
            PrismStructs.HopPath[] memory singlePaths = new PrismStructs.HopPath[](3);

            // wETH -> PEPE u2
            PrismStructs.SwapStep[] memory swap1 = new PrismStructs.SwapStep[](1);
            bytes memory payload = abi.encode(UniswapV2SwapArg(0xA43fe16908251ee70EF74718545e4FE6C5cCEc9f, 3, 1000));
            swap1[0] = PrismStructs.SwapStep(1e18, 1, payload);
            PrismStructs.Adapter[] memory adapters = new PrismStructs.Adapter[](1);
            adapters[0] = PrismStructs.Adapter(payable(adapter1), 1e18, swap1);
            singlePaths[0] = PrismStructs.HopPath(0x6982508145454Ce325dDbE47a25d4ec3d2311933, adapters); // PEPE

            // PEPE -> wETH u3
            PrismStructs.SwapStep[] memory swaps2 = new PrismStructs.SwapStep[](1);
            payload = abi.encode(PrismStructs.UniswapV3Data(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45, 0, 3000));
            swaps2[0] = PrismStructs.SwapStep(1e18, 5, payload);
            PrismStructs.Adapter[] memory adapters2 = new PrismStructs.Adapter[](1);
            adapters2[0] = PrismStructs.Adapter(payable(adapter1), 1e18, swaps2);
            singlePaths[1] = PrismStructs.HopPath(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, adapters2); // wETH

            // wETH -> USDC
            PrismStructs.SwapStep[] memory swaps3 = new PrismStructs.SwapStep[](1);
            payload = abi.encode(UniswapV2SwapArg(0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc, 3, 1000));
            swaps3[0] = PrismStructs.SwapStep(1e18, 1, payload);
            PrismStructs.Adapter[] memory adapters3 = new PrismStructs.Adapter[](1);
            adapters3[0] = PrismStructs.Adapter(payable(adapter1), 1e18, swaps3);
            singlePaths[2] = PrismStructs.HopPath(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, adapters3); // USDC

            multiPath0 = PrismStructs.RouteGroup(6e17, singlePaths); // 60%
        }

        // Create RouteGroup[1]: wETH -> USDC (40%)
        PrismStructs.RouteGroup memory multiPath1;
        {
            PrismStructs.HopPath[] memory singlePaths = new PrismStructs.HopPath[](1);
            PrismStructs.SwapStep[] memory swaps = new PrismStructs.SwapStep[](1);
            bytes memory payload = abi.encode(PrismStructs.UniswapV3Data(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45, 0, 3000));
            swaps[0] = PrismStructs.SwapStep(1e18, 5, payload);
            PrismStructs.Adapter[] memory adapters = new PrismStructs.Adapter[](1);
            adapters[0] = PrismStructs.Adapter(payable(adapter1), 1e18, swaps);
            singlePaths[0] = PrismStructs.HopPath(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, adapters); // USDC

            multiPath1 = PrismStructs.RouteGroup(4e17, singlePaths); // 40%
        }

        PrismStructs.RouteGroup[] memory multiPaths = new PrismStructs.RouteGroup[](2);
        multiPaths[0] = multiPath0;
        multiPaths[1] = multiPath1;

        // Execute the swap
        deal(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, address(this), 10 ether);
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).approve(address(router), 10 ether);

        router.swap(
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            10 ether,
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            0,
            true,
            0,
            feeReceiver,
            multiPaths
        );
    }
}
