// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../Initial.t.sol";

/// @notice ETH mainnet test
contract Uv2ExecutorTest is PrismBaseTest {
    using SafeERC20 for IERC20;

    function testFromWethToUSDC() public {
        // weth -> usdc 100%
        PrismStructs.RouteGroup memory multiPath0;
        PrismStructs.SwapStep[] memory swaps = new PrismStructs.SwapStep[](1);
        UniswapV2SwapArg memory arg = UniswapV2SwapArg(0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852, 3, 1000);
        bytes memory payload = abi.encode(arg);

        PrismStructs.SwapStep memory simpleSwap = PrismStructs.SwapStep(1e18, 1, payload);
        swaps[0] = simpleSwap;
        PrismStructs.Adapter[] memory adapters = new PrismStructs.Adapter[](1);
        PrismStructs.Adapter memory adapter = PrismStructs.Adapter(payable(adapter1), 1e18, swaps);
        adapters[0] = adapter;
        PrismStructs.HopPath memory singlePath0 = PrismStructs.HopPath(0xdAC17F958D2ee523a2206206994597C13D831ec7, adapters);
        PrismStructs.HopPath[] memory singlePaths = new PrismStructs.HopPath[](1);
        singlePaths[0] = singlePath0;
        multiPath0 = PrismStructs.RouteGroup(1e18, singlePaths);

        PrismStructs.RouteGroup[] memory multiPaths = new PrismStructs.RouteGroup[](1);
        multiPaths[0] = multiPath0;
        deal(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, address(this), 1 ether);
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).approve(address(router), 1 ether);

        router.swap(
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            1 ether,
            0xdAC17F958D2ee523a2206206994597C13D831ec7,
            1000e6,
            false,
            0,
            feeReceiver,
            multiPaths
        );
        uint256 wethBalance = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).balanceOf(address(this));
        console.log("weth balance", wethBalance);
        uint256 usdtBalance = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7).balanceOf(address(this));
        console.log("usdt balance", usdtBalance);
        assertEq(wethBalance, 0);
    }

    function testFromEthToUSDC() public {
        // eth -> weth -> usdc 100%
        PrismStructs.RouteGroup memory multiPath0;
        PrismStructs.HopPath[] memory singlePaths = new PrismStructs.HopPath[](2);
        {
            PrismStructs.SwapStep[] memory wethSwaps = new PrismStructs.SwapStep[](1);
            PrismStructs.SwapStep memory wethSimpleSwap = PrismStructs.SwapStep(1e18, 11, "");
            wethSwaps[0] = wethSimpleSwap;
            PrismStructs.Adapter[] memory wethAdapters = new PrismStructs.Adapter[](1);
            PrismStructs.Adapter memory wethAdapter = PrismStructs.Adapter(payable(adapter1), 1e18, wethSwaps);
            wethAdapters[0] = wethAdapter;
            PrismStructs.HopPath memory wethSinglePath =
                PrismStructs.HopPath(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, wethAdapters);
            singlePaths[0] = wethSinglePath;
        }
        {
            PrismStructs.SwapStep[] memory swaps = new PrismStructs.SwapStep[](1);
            UniswapV2SwapArg memory arg = UniswapV2SwapArg(0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852, 3, 1000);
            bytes memory payload = abi.encode(arg);
            PrismStructs.SwapStep memory simpleSwap = PrismStructs.SwapStep(1e18, 1, payload);
            swaps[0] = simpleSwap;
            PrismStructs.Adapter[] memory adapters = new PrismStructs.Adapter[](1);
            PrismStructs.Adapter memory adapter = PrismStructs.Adapter(payable(adapter1), 1e18, swaps);
            adapters[0] = adapter;
            PrismStructs.HopPath memory singlePath0 = PrismStructs.HopPath(0xdAC17F958D2ee523a2206206994597C13D831ec7, adapters);
            singlePaths[1] = singlePath0;
        }
        multiPath0 = PrismStructs.RouteGroup(1e18, singlePaths);
        PrismStructs.RouteGroup[] memory multiPaths = new PrismStructs.RouteGroup[](1);
        multiPaths[0] = multiPath0;
        vm.deal(address(this), 2 ether);

        router.swap{value: 1 ether}(
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            1 ether,
            0xdAC17F958D2ee523a2206206994597C13D831ec7,
            1000e6,
            true,
            0,
            feeReceiver,
            multiPaths
        );
        uint256 ethBalance = (address(this)).balance;
        console.logUint(ethBalance);
        uint256 usdtBalance = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7).balanceOf(address(this));
        console.logUint(usdtBalance);
        assertTrue(usdtBalance > 1000e6);

        // charge fee in from Token
        router.swap{value: 1 ether}(
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            1 ether,
            0xdAC17F958D2ee523a2206206994597C13D831ec7,
            1000e6,
            true,
            1e15,
            feeReceiver,
            multiPaths
        );
    }

    function testFromUSDCToETHtt() public {
        // usdc -> weth - eth 100%
        PrismStructs.RouteGroup memory multiPath0;
        PrismStructs.HopPath[] memory singlePaths = new PrismStructs.HopPath[](2);
        {
            PrismStructs.SwapStep[] memory swaps = new PrismStructs.SwapStep[](1);
            UniswapV2SwapArg memory arg = UniswapV2SwapArg(0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852, 3, 1000);
            bytes memory payload = abi.encode(arg);
            PrismStructs.SwapStep memory simpleSwap = PrismStructs.SwapStep(1e18, 1, payload);
            swaps[0] = simpleSwap;
            PrismStructs.Adapter[] memory adapters = new PrismStructs.Adapter[](1);
            PrismStructs.Adapter memory adapter = PrismStructs.Adapter(payable(adapter1), 1e18, swaps);
            adapters[0] = adapter;
            PrismStructs.HopPath memory singlePath0 = PrismStructs.HopPath(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, adapters);
            singlePaths[0] = singlePath0;
        }
        {
            PrismStructs.SwapStep[] memory wethSwaps = new PrismStructs.SwapStep[](1);
            PrismStructs.SwapStep memory wethSimpleSwap = PrismStructs.SwapStep(1e18, 11, ""); // swapType 11 = WETH wrap/unwrap
            wethSwaps[0] = wethSimpleSwap;
            PrismStructs.Adapter[] memory wethAdapters = new PrismStructs.Adapter[](1);
            PrismStructs.Adapter memory wethAdapter = PrismStructs.Adapter(payable(adapter1), 1e18, wethSwaps);
            wethAdapters[0] = wethAdapter;
            PrismStructs.HopPath memory wethSinglePath =
                PrismStructs.HopPath(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, wethAdapters);
            singlePaths[1] = wethSinglePath;
        }

        multiPath0 = PrismStructs.RouteGroup(1e18, singlePaths);
        PrismStructs.RouteGroup[] memory multiPaths = new PrismStructs.RouteGroup[](1);
        multiPaths[0] = multiPath0;
        deal(0xdAC17F958D2ee523a2206206994597C13D831ec7, address(this), 2000e6);
        IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7).forceApprove(address(router), 2000e6);

        cheats.expectRevert("PrismRouter: slippage limit exceeded");
        router.swap(
            0xdAC17F958D2ee523a2206206994597C13D831ec7,
            2000e6,
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            2e18,
            false,
            0,
            feeReceiver,
            multiPaths
        );

        uint256 ethBalancebefore = (address(this)).balance;
        router.swap(
            0xdAC17F958D2ee523a2206206994597C13D831ec7,
            2000e6,
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            5e17,
            false,
            0,
            feeReceiver,
            multiPaths
        );
        uint256 ethBalance = (address(this)).balance;
        console.log("eth balance add", ethBalance - ethBalancebefore);
        uint256 usdtBalance = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7).balanceOf(address(this));
        console.log("usdt balance", usdtBalance);
        assertTrue(ethBalance - ethBalancebefore > 5e17);
        assertEq(usdtBalance, 0);
    }

    function testFromUSDCToETHChargeFee() public {
        // usdc -> weth -> eth 100%
        PrismStructs.RouteGroup memory multiPath0;
        PrismStructs.HopPath[] memory singlePaths = new PrismStructs.HopPath[](2);
        {
            PrismStructs.SwapStep[] memory swaps = new PrismStructs.SwapStep[](1);
            UniswapV2SwapArg memory arg = UniswapV2SwapArg(0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852, 3, 1000);
            bytes memory payload = abi.encode(arg);
            PrismStructs.SwapStep memory simpleSwap = PrismStructs.SwapStep(1e18, 1, payload);
            swaps[0] = simpleSwap;
            PrismStructs.Adapter[] memory adapters = new PrismStructs.Adapter[](1);
            PrismStructs.Adapter memory adapter = PrismStructs.Adapter(payable(adapter1), 1e18, swaps);
            adapters[0] = adapter;
            PrismStructs.HopPath memory singlePath0 = PrismStructs.HopPath(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, adapters);
            singlePaths[0] = singlePath0;
        }
        {
            PrismStructs.SwapStep[] memory wethSwaps = new PrismStructs.SwapStep[](1);
            PrismStructs.SwapStep memory wethSimpleSwap = PrismStructs.SwapStep(1e18, 11, "");
            wethSwaps[0] = wethSimpleSwap;
            PrismStructs.Adapter[] memory wethAdapters = new PrismStructs.Adapter[](1);
            PrismStructs.Adapter memory wethAdapter = PrismStructs.Adapter(payable(adapter1), 1e18, wethSwaps);
            wethAdapters[0] = wethAdapter;
            PrismStructs.HopPath memory wethSinglePath =
                PrismStructs.HopPath(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, wethAdapters);
            singlePaths[1] = wethSinglePath;
        }

        multiPath0 = PrismStructs.RouteGroup(1e18, singlePaths);
        PrismStructs.RouteGroup[] memory multiPaths = new PrismStructs.RouteGroup[](1);
        multiPaths[0] = multiPath0;
        deal(0xdAC17F958D2ee523a2206206994597C13D831ec7, address(this), 2000e6);
        IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7).forceApprove(address(router), 2000e6);

        uint256 ethBalancebefore = (address(this)).balance;
        router.swap(
            0xdAC17F958D2ee523a2206206994597C13D831ec7,
            2000e6,
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            4e17,
            false,
            1e15,
            feeReceiver,
            multiPaths
        );
        uint256 ethBalance = (address(this)).balance;
        console.log("eth balance add", ethBalance - ethBalancebefore);
        uint256 usdtBalance = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7).balanceOf(feeReceiver);
        console.log("usdt balance", usdtBalance);
        uint256 wethFeeBalance = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).balanceOf(feeReceiver);
        console.log("weth fee balance", wethFeeBalance);
        assertEq(usdtBalance, 0);
    }

    function testFromCultToETH() public {
        // weth -> usdc 100%
        PrismStructs.RouteGroup memory multiPath0;
        PrismStructs.SwapStep[] memory swaps = new PrismStructs.SwapStep[](1);
        UniswapV2SwapArg memory arg = UniswapV2SwapArg(0x5281E311734869C64ca60eF047fd87759397EFe6, 3, 1000);
        bytes memory payload = abi.encode(arg);

        PrismStructs.SwapStep memory simpleSwap = PrismStructs.SwapStep(1e18, 1, payload);
        swaps[0] = simpleSwap;
        PrismStructs.Adapter[] memory adapters = new PrismStructs.Adapter[](1);
        PrismStructs.Adapter memory adapter = PrismStructs.Adapter(payable(adapter1), 1e18, swaps);
        adapters[0] = adapter;
        PrismStructs.HopPath memory singlePath0 = PrismStructs.HopPath(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, adapters);
        PrismStructs.HopPath[] memory singlePaths = new PrismStructs.HopPath[](1);
        singlePaths[0] = singlePath0;
        multiPath0 = PrismStructs.RouteGroup(1e18, singlePaths);

        PrismStructs.RouteGroup[] memory multiPaths = new PrismStructs.RouteGroup[](1);
        multiPaths[0] = multiPath0;
        deal(0xf0f9D895aCa5c8678f706FB8216fa22957685A13, address(this), 1670158226688697842729069);
        IERC20(0xf0f9D895aCa5c8678f706FB8216fa22957685A13).approve(address(router), 1670158226688697842729069);

        router.swap(
            0xf0f9D895aCa5c8678f706FB8216fa22957685A13,
            1670158226688697842729069,
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            9000000000000,
            false,
            0,
            feeReceiver,
            multiPaths
        );
    }
}
