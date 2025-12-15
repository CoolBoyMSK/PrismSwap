// /*
// SPDX-License-Identifier: MIT
// */
// pragma solidity ^0.8.25;

// import "../Initial.t.sol";

// /// @notice OP test
// contract VelodromeExecutorTest is PrismBaseTest {
//     using SafeERC20 for IERC20;

//     function testVelodromeExecutorFromWethToOUSDT() public {
//         VelodromeExecutor.VelodromeData memory arg = VelodromeExecutor.VelodromeData(
//             // router
//             0x0792a633F0c19c351081CF4B211F68F79bCc9676,
//             0,
//             100
//         );
//         PrismStructs.RouteGroup memory multiPath0;
//         PrismStructs.SwapStep[] memory swaps = new PrismStructs.SwapStep[](1);
//         bytes memory payload = abi.encode(arg);

//         PrismStructs.SwapStep memory simpleSwap = PrismStructs.SwapStep(1e18, 6, payload);
//         swaps[0] = simpleSwap;
//         PrismStructs.Adapter[] memory adapters = new PrismStructs.Adapter[](1);
//         PrismStructs.Adapter memory adapter = PrismStructs.Adapter(payable(adapter1), 1e18, swaps);
//         adapters[0] = adapter;
//         PrismStructs.HopPath memory singlePath = PrismStructs.HopPath(
//             // toToken
//             0x1217BfE6c773EEC6cc4A38b5Dc45B92292B6E189,
//             adapters
//         );
//         PrismStructs.HopPath[] memory singlePaths = new PrismStructs.HopPath[](1);
//         singlePaths[0] = singlePath;
//         multiPath0 = PrismStructs.RouteGroup(1e18, singlePaths);

//         PrismStructs.RouteGroup[] memory multiPaths = new PrismStructs.RouteGroup[](1);
//         multiPaths[0] = multiPath0;
//         deal(0x4200000000000000000000000000000000000006, address(this), 1 ether);
//         IERC20(0x4200000000000000000000000000000000000006).approve(address(router), 1 ether);

//         router.swap(
//             address(executor),
//             0x4200000000000000000000000000000000000006,
//             1 ether,
//             0x1217BfE6c773EEC6cc4A38b5Dc45B92292B6E189,
//             1000e6,
//             false,
//             0,
//             feeReceiver,
//             multiPaths
//         );
//         uint256 oUSDTBalance = IERC20(0x1217BfE6c773EEC6cc4A38b5Dc45B92292B6E189).balanceOf(address(this));
//         console.log(oUSDTBalance);
//         assertTrue(oUSDTBalance > 0, "oUSDTBalance should be greater than 0");
//     }
// }
