// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./PrismHubBase.sol";
import {Test} from "forge-std/Test.sol";

contract PrismHubTest is PrismHubBase {
    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event BalanceInfo(string message, uint256 fromBalanceChange, uint256 toBalanceChange, uint256 fee);

    function testHubSwapRevert() public {
        deal(weth, address(this), 1 ether);
        IERC20(weth).approve(address(hubContract), 1 ether);

        vm.expectRevert("TokenPairInvalid()");
        hubContract.swap(
            PrismHub.TradeParams({
                providerId: "oneinch",
                fromToken: weth,
                fromTokenAmount: 1e18,
                toToken: weth,
                minAmountOut: 2000e18,
                feeRate: 0,
                feeOnFromToken: true,
                feeReceiver: feeReceiver,
                data: hex"8770ba91000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000de0b6b3a764000000000000000000000000000000000000000000000000007fdfce91e8b07ec1b628000000000000000000000088e6a0c2ddd26feeb64f039a2c41296fcb3f56402000000000000000000000005777d92f208679db4b9778590fa3cab3ac9e21682a6f45f2"
            })
        );

        vm.expectRevert("IncorrectFeeReceiver()");
        hubContract.swap(
            PrismHub.TradeParams({
                providerId: "oneinch",
                fromToken: weth,
                fromTokenAmount: 1e18,
                toToken: dai,
                minAmountOut: 2000e18,
                feeRate: 0,
                feeOnFromToken: true,
                feeReceiver: address(hubContract),
                data: hex"8770ba91000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000de0b6b3a764000000000000000000000000000000000000000000000000007fdfce91e8b07ec1b628000000000000000000000088e6a0c2ddd26feeb64f039a2c41296fcb3f56402000000000000000000000005777d92f208679db4b9778590fa3cab3ac9e21682a6f45f2"
            })
        );

        vm.expectRevert("FeeRateTooBig()");
        hubContract.swap(
            PrismHub.TradeParams({
                providerId: "oneinch",
                fromToken: weth,
                fromTokenAmount: 1e18,
                toToken: dai,
                minAmountOut: 2000e18,
                feeRate: 1e17,
                feeOnFromToken: true,
                feeReceiver: feeReceiver,
                data: hex"8770ba91000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000de0b6b3a764000000000000000000000000000000000000000000000000007fdfce91e8b07ec1b628000000000000000000000088e6a0c2ddd26feeb64f039a2c41296fcb3f56402000000000000000000000005777d92f208679db4b9778590fa3cab3ac9e21682a6f45f2"
            })
        );

        vm.expectRevert("SlippageLimitExceeded()");
        hubContract.swap(
            PrismHub.TradeParams({
                providerId: "oneinch",
                fromToken: weth,
                fromTokenAmount: 1e18,
                toToken: dai,
                minAmountOut: 3000e18,
                feeRate: 0,
                feeOnFromToken: true,
                feeReceiver: feeReceiver,
                data: hex"8770ba91000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000de0b6b3a764000000000000000000000000000000000000000000000000007fdfce91e8b07ec1b628000000000000000000000088e6a0c2ddd26feeb64f039a2c41296fcb3f56402000000000000000000000005777d92f208679db4b9778590fa3cab3ac9e21682a6f45f2"
            })
        );

        vm.expectRevert("FailedCall()");
        hubContract.swap(
            PrismHub.TradeParams({
                providerId: "oneinch",
                fromToken: weth,
                fromTokenAmount: 1e18,
                toToken: dai,
                minAmountOut: 2000e18,
                feeRate: 1e16,
                feeOnFromToken: true,
                feeReceiver: feeReceiver,
                data: "0x1"
            })
        );
        vm.startPrank(address(0xdeadbeef));
        address spender = address(hubContract.spender());
        vm.expectRevert(PrismErrors.Forbidden.selector);
        PrismProxy(payable(address(hubContract.swapProxy()))).swap(
            address(oneinchAdapter),
            abi.encodeWithSelector(
                OneinchAdapter.swapOnAdapter.selector,
                weth,
                1e18,
                dai,
                address(this),
                hex"8770ba91000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000de0b6b3a764000000000000000000000000000000000000000000000000007fdfce91e8b07ec1b628000000000000000000000088e6a0c2ddd26feeb64f039a2c41296fcb3f56402000000000000000000000005777d92f208679db4b9778590fa3cab3ac9e21682a6f45f2"
            )
        );
        vm.stopPrank();
    }

    function testAdmin() public {
        deal(weth, address(this), 1 ether);
        IERC20(weth).approve(address(hubContract), 1 ether);
        // pause debank swap
        hubContract.pause();
        cheats.expectRevert("PrismAdmin: paused");
        hubContract.swap(
            PrismHub.TradeParams({
                providerId: "oneinch",
                fromToken: weth,
                fromTokenAmount: 1e18,
                toToken: dai,
                minAmountOut: 2000e18,
                feeRate: 0,
                feeOnFromToken: true,
                feeReceiver: feeReceiver,
                data: hex"8770ba91000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000de0b6b3a764000000000000000000000000000000000000000000000000008779867b86e05e444e280000000000000000000000e0554a476a092703abdb3ef35c80e0d76d32939f2000000000000000000000005777d92f208679db4b9778590fa3cab3ac9e21682a6f45f2"
            })
        );
        hubContract.unpause();

        cheats.expectRevert("PrismAdmin: not paused");
        hubContract.unpause();

        // test updateAdmins
        cheats.expectRevert("PrismAdmin: zero address");
        hubContract.updateAdmins(address(0));
        cheats.expectRevert("PrismAdmin: already an admin");
        hubContract.updateAdmins(address(this));
        hubContract.pause();
        cheats.expectRevert("PrismAdmin: unpause first");
        hubContract.updateAdmins(0x5D7c30c04c6976D4951209E55FB158DBF9F8F287);
        hubContract.unpause();

        // test updateAdmins by admin
        vm.startPrank(admins[0]);
        hubContract.updateAdmins(0x5D7c30c04c6976D4951209E55FB158DBF9F8F287);
        cheats.expectRevert("PrismAdmin: not admin");
        hubContract.pause();
        vm.stopPrank();

        cheats.expectRevert("AdapterDoesNotExist()");
        hubContract.swap(
            PrismHub.TradeParams({
                providerId: "uniswap",
                fromToken: weth,
                fromTokenAmount: 1e18,
                toToken: dai,
                minAmountOut: 2000e18,
                feeRate: 0,
                feeOnFromToken: true,
                feeReceiver: feeReceiver,
                data: hex"8770ba91000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000de0b6b3a764000000000000000000000000000000000000000000000000008779867b86e05e444e280000000000000000000000e0554a476a092703abdb3ef35c80e0d76d32939f2000000000000000000000005777d92f208679db4b9778590fa3cab3ac9e21682a6f45f2"
            })
        );

        vm.startPrank(0x5D7c30c04c6976D4951209E55FB158DBF9F8F287);
        hubContract.pause();
        vm.stopPrank();

        vm.startPrank(admins[2]);
        hubContract.pause();
        vm.stopPrank();

        // test pasued by multiple admins
        cheats.expectRevert("PrismAdmin: multiple admins paused");
        hubContract.unpause();
        bool[3] memory adminPauseStates = hubContract.getAdminPauseStates();
        assertEq(adminPauseStates[0], true);
        assertEq(adminPauseStates[1], false);
        assertEq(adminPauseStates[2], true);
        hubContract.getAdmins();

        vm.startPrank(admins[0]);
        cheats.expectRevert("PrismAdmin: not admin");
        hubContract.setAdapter("oneinch", address(oneinchAdapter), OneinchAdapter.swapOnAdapter.selector);
        vm.stopPrank();

        hubContract.removeAdapter("oneinch");
        (, bool isRegistered,) = hubContract.adapters("oneinch");
        assertEq(isRegistered, false);

        cheats.expectRevert("AdapterDoesNotExist()");
        hubContract.removeAdapter("oneinch");

        cheats.expectRevert("AdapterAddressZero()");
        hubContract.setAdapter("oneinch", address(0), OneinchAdapter.swapOnAdapter.selector);

        hubContract.setAdapter("oneinch", address(oneinchAdapter), OneinchAdapter.swapOnAdapter.selector);

        cheats.expectRevert("AdapterExists()");
        hubContract.setAdapter("oneinch", address(oneinchAdapter), OneinchAdapter.swapOnAdapter.selector);

        cheats.expectRevert("AdapterExists()");
        hubContract.setAdapter("oneinchV6", address(oneinchAdapter), OneinchAdapter.swapOnAdapter.selector);

        hubContract.getAdapters();
    }

    function testHubSwapWETHTODAI() public {
        deal(weth, address(this), 1 ether);
        IERC20(weth).approve(address(hubContract), 1 ether);

        uint256 wethBalanceBefore = IERC20(weth).balanceOf(address(this));
        uint256 daiBalanceBefore = IERC20(dai).balanceOf(address(this));

        emit BalanceInfo("Before swap", wethBalanceBefore, daiBalanceBefore, 0);

        hubContract.swap(
            PrismHub.TradeParams({
                providerId: "oneinch",
                fromToken: weth,
                fromTokenAmount: 1e18,
                toToken: dai,
                minAmountOut: 2000e18,
                feeRate: 0,
                feeOnFromToken: true,
                feeReceiver: feeReceiver,
                data: hex"8770ba91000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000de0b6b3a764000000000000000000000000000000000000000000000000007fdfce91e8b07ec1b628000000000000000000000088e6a0c2ddd26feeb64f039a2c41296fcb3f56402000000000000000000000005777d92f208679db4b9778590fa3cab3ac9e21682a6f45f2"
            })
        );

        uint256 wethBalanceAfter = IERC20(weth).balanceOf(address(this));
        uint256 daiBalanceAfter = IERC20(dai).balanceOf(address(this));
        uint256 fee = IERC20(weth).balanceOf(feeReceiver);

        emit BalanceInfo("After swap", wethBalanceAfter, daiBalanceAfter, fee);

        assertTrue(daiBalanceAfter > daiBalanceBefore, "Should receive DAI");
        assertTrue(wethBalanceAfter < wethBalanceBefore, "Should spend WETH");
    }

    function testHubSwapWETHTODAIChargeFeeOnWETH() public {
        deal(weth, address(this), 1 ether);
        IERC20(weth).approve(address(hubContract), 1 ether);
        uint256 wethBalanceBefore = IERC20(weth).balanceOf(address(this));
        uint256 daiBalanceBefore = IERC20(dai).balanceOf(address(this));
        emit BalanceInfo("Before swap", wethBalanceBefore, daiBalanceBefore, 0);
        hubContract.swap(
            PrismHub.TradeParams({
                providerId: "oneinch",
                fromToken: weth,
                fromTokenAmount: 1e18,
                toToken: dai,
                minAmountOut: 2000e18,
                feeRate: 1e16,
                feeOnFromToken: true,
                feeReceiver: feeReceiver,
                data: hex"8770ba91000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000dbd2fc137a3000000000000000000000000000000000000000000000000007ea4d769b38feec540288000000000000000000000c7bbec68d12a0d1830360f8ec58fa599ba1b0e9b20000000000000000000000048da0965ab2d2cbf1c17c09cfb5cbe67ad5b14062a6f45f2"
            })
        );
        uint256 wethBalanceAfter = IERC20(weth).balanceOf(address(this));
        uint256 daiBalanceAfter = IERC20(dai).balanceOf(address(this));
        uint256 fee = IERC20(weth).balanceOf(feeReceiver);

        emit BalanceInfo("After swap", wethBalanceAfter, daiBalanceAfter, fee);
        assertTrue(daiBalanceAfter > daiBalanceBefore, "Should receive DAI");
        assertTrue(wethBalanceAfter < wethBalanceBefore, "Should spend WETH");
    }

    function testHubSwapInOneinchWithRemainingTokens() public {
        deal(weth, address(this), 1 ether);
        IERC20(weth).approve(address(hubContract), 1 ether);
        uint256 wethBalanceBefore = IERC20(weth).balanceOf(address(this));
        uint256 daiBalanceBefore = IERC20(dai).balanceOf(address(this));
        emit BalanceInfo("Before swap", wethBalanceBefore, daiBalanceBefore, 0);
        hubContract.swap(
            PrismHub.TradeParams({
                providerId: "oneinch",
                fromToken: weth,
                fromTokenAmount: 1e18,
                toToken: dai,
                minAmountOut: 2000e18,
                feeRate: 0,
                feeOnFromToken: true,
                feeReceiver: feeReceiver,
                data: hex"8770ba91000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000dbd2fc137a3000000000000000000000000000000000000000000000000007ea4d769b38feec540288000000000000000000000c7bbec68d12a0d1830360f8ec58fa599ba1b0e9b20000000000000000000000048da0965ab2d2cbf1c17c09cfb5cbe67ad5b14062a6f45f2"
            })
        );
        uint256 wethBalanceAfter = IERC20(weth).balanceOf(address(this));
        uint256 daiBalanceAfter = IERC20(dai).balanceOf(address(this));

        emit BalanceInfo("After swap", wethBalanceAfter, daiBalanceAfter, 0);
        assertTrue(daiBalanceAfter > daiBalanceBefore, "Should receive DAI");
        assertTrue(wethBalanceAfter < wethBalanceBefore, "Should spend WETH");

        assertEq(wethBalanceBefore - wethBalanceAfter, 99e16, "Should spend exactly 99e16 ether");
    }

    function testHubSwapWETHTODAIChargeFeeOnDai() public {
        deal(weth, address(this), 1 ether);
        IERC20(weth).approve(address(hubContract), 1 ether);
        uint256 wethBalanceBefore = IERC20(weth).balanceOf(address(this));
        uint256 daiBalanceBefore = IERC20(dai).balanceOf(address(this));
        emit BalanceInfo("Before swap", wethBalanceBefore, daiBalanceBefore, 0);
        hubContract.swap(
            PrismHub.TradeParams({
                providerId: "oneinch",
                fromToken: weth,
                fromTokenAmount: 1e18,
                toToken: dai,
                minAmountOut: 2000e18,
                feeRate: 1e16,
                feeOnFromToken: false,
                feeReceiver: feeReceiver,
                data: hex"8770ba91000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000de0b6b3a764000000000000000000000000000000000000000000000000007fdfce91e8b07ec1b628000000000000000000000088e6a0c2ddd26feeb64f039a2c41296fcb3f56402000000000000000000000005777d92f208679db4b9778590fa3cab3ac9e21682a6f45f2"
            })
        );
        uint256 wethBalanceAfter = IERC20(weth).balanceOf(address(this));
        uint256 daiBalanceAfter = IERC20(dai).balanceOf(address(this));
        uint256 fee = IERC20(dai).balanceOf(feeReceiver);
        emit BalanceInfo("After swap", wethBalanceAfter, daiBalanceAfter, fee);
        assertTrue(daiBalanceAfter > daiBalanceBefore, "Should receive DAI");
        assertTrue(wethBalanceAfter < wethBalanceBefore, "Should spend WETH");
    }

    function testHubSwapEthToUsdc() public {
        vm.deal(address(this), 1 ether);
        uint256 ethBalanceBefore = address(this).balance;
        uint256 usdcBalanceBefore = IERC20(usdc).balanceOf(address(this));
        uint256 feeBefore = IERC20(usdc).balanceOf(feeReceiver);

        vm.expectRevert("IncorrectMsgValue()");
        hubContract.swap{value: 1e17}(
            PrismHub.TradeParams({
                providerId: "oneinch",
                fromToken: eth,
                fromTokenAmount: 1e18,
                toToken: usdc,
                minAmountOut: 2000e6,
                feeRate: 0,
                feeOnFromToken: false,
                feeReceiver: feeReceiver,
                data: hex"a76dfc3b000000000000000000000000000000000000000000000000000000008cb4d23820000000000000000000000088e6a0c2ddd26feeb64f039a2c41296fcb3f56402a6f45f2"
            })
        );

        hubContract.swap{value: 1 ether}(
            PrismHub.TradeParams({
                providerId: "oneinch",
                fromToken: eth,
                fromTokenAmount: 1e18,
                toToken: usdc,
                minAmountOut: 2000e6,
                feeRate: 0,
                feeOnFromToken: false,
                feeReceiver: feeReceiver,
                data: hex"a76dfc3b000000000000000000000000000000000000000000000000000000008cb4d23820000000000000000000000088e6a0c2ddd26feeb64f039a2c41296fcb3f56402a6f45f2"
            })
        );
        uint256 ethBalanceAfter = address(this).balance;
        uint256 usdcBalanceAfter = IERC20(usdc).balanceOf(address(this));
        uint256 fee = IERC20(usdc).balanceOf(feeReceiver);
        emit BalanceInfo(
            "After swap", ethBalanceBefore - ethBalanceAfter, usdcBalanceAfter - usdcBalanceBefore, fee - feeBefore
        );
        assertTrue(usdcBalanceAfter > usdcBalanceBefore, "Should receive USDC");
        assertTrue(ethBalanceAfter < ethBalanceBefore, "Should spend ETH");
    }

    function testHubSwapEthToUsdcChargeFeeOnEth() public {
        vm.deal(address(this), 1 ether);
        uint256 ethBalanceBefore = address(this).balance;
        uint256 usdcBalanceBefore = IERC20(usdc).balanceOf(address(this));
        uint256 feeBefore = feeReceiver.balance;
        hubContract.swap{value: 1 ether}(
            PrismHub.TradeParams({
                providerId: "oneinch",
                fromToken: eth,
                fromTokenAmount: 1e18,
                toToken: usdc,
                minAmountOut: 2000e6,
                feeRate: 1e16,
                feeOnFromToken: true,
                feeReceiver: feeReceiver,
                data: hex"a76dfc3b000000000000000000000000000000000000000000000000000000008b5e53d8200000000000000000000000e0554a476a092703abdb3ef35c80e0d76d32939f2a6f45f2"
            })
        );
        uint256 ethBalanceAfter = address(this).balance;
        uint256 usdcBalanceAfter = IERC20(usdc).balanceOf(address(this));
        uint256 fee = feeReceiver.balance;
        emit BalanceInfo(
            "After swap", ethBalanceBefore - ethBalanceAfter, usdcBalanceAfter - usdcBalanceBefore, fee - feeBefore
        );
        assertTrue(usdcBalanceAfter > usdcBalanceBefore, "Should receive USDC");
        assertTrue(ethBalanceAfter < ethBalanceBefore, "Should spend ETH");
    }

    //will swap all tokens
    // function testHubSwapInOneinchWithRemainingTokensETH() public {
    //     vm.deal(address(this), 2 ether);
    //     uint256 ethBalanceBefore = address(this).balance;
    //     uint256 usdcBalanceBefore = IERC20(usdc).balanceOf(address(this));
    //     uint256 feeBefore = feeReceiver.balance;
    //     hubContract.swap{value: 2 ether}(
    //         PrismHub.TradeParams({
    //             providerId: "oneinch",
    //             fromToken: eth,
    //             fromTokenAmount: 2e18,
    //             toToken: usdc,
    //             minAmountOut: 2000e6,
    //             feeRate: 0,
    //             feeOnFromToken: true,
    //             feeReceiver: feeReceiver,
    //             data: hex"a76dfc3b000000000000000000000000000000000000000000000000000000008b5e53d8200000000000000000000000e0554a476a092703abdb3ef35c80e0d76d32939f2a6f45f2"
    //         })
    //     );
    //     uint256 ethBalanceAfter = address(this).balance;
    //     uint256 usdcBalanceAfter = IERC20(usdc).balanceOf(address(this));
    //     uint256 fee = feeReceiver.balance;
    //     emit BalanceInfo(
    //         "After swap", ethBalanceBefore - ethBalanceAfter, usdcBalanceAfter - usdcBalanceBefore, fee - feeBefore
    //     );
    //     assertTrue(usdcBalanceAfter > usdcBalanceBefore, "Should receive USDC");
    //     assertTrue(ethBalanceAfter < ethBalanceBefore, "Should spend ETH");

    //     assertEq(ethBalanceBefore - ethBalanceAfter, 99e16, "Should spend exactly 99e16 ether");
    // }

    function testHubSwapUsdcToEthChageFeeOnEth() public {
        deal(usdc, address(this), 3000e6);
        IERC20(usdc).approve(address(hubContract), 3000e6);
        uint256 ethBalanceBefore = address(this).balance;
        uint256 usdcBalanceBefore = IERC20(usdc).balanceOf(address(this));
        uint256 feeBefore = feeReceiver.balance;
        hubContract.swap(
            PrismHub.TradeParams({
                providerId: "oneinch",
                fromToken: usdc,
                fromTokenAmount: 3000e6,
                toToken: eth,
                minAmountOut: 1e18,
                feeRate: 1e16,
                feeOnFromToken: false,
                feeReceiver: feeReceiver,
                data: hex"83800a8e000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb4800000000000000000000000000000000000000000000000000000000b2d05e000000000000000000000000000000000000000000000000000ec9f3057528b05b38800000000000000000000088e6a0c2ddd26feeb64f039a2c41296fcb3f56402a6f45f2"
            })
        );
        uint256 ethBalanceAfter = address(this).balance;
        uint256 usdcBalanceAfter = IERC20(usdc).balanceOf(address(this));
        uint256 fee = feeReceiver.balance;
        emit BalanceInfo(
            "After swap", usdcBalanceBefore - usdcBalanceAfter, ethBalanceAfter - ethBalanceBefore, fee - feeBefore
        );
        assertTrue(usdcBalanceAfter < usdcBalanceBefore, "Should spend USDC");
        assertTrue(ethBalanceAfter > ethBalanceBefore, "Should receive ETH");
    }
}
