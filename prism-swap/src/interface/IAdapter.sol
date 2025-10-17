// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../library/PrismStructs.sol";

interface IAdapter {
    function executeSimpleSwap(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        PrismStructs.SwapStep[] memory swaps
    ) external payable;
}
