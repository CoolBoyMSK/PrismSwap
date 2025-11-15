// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

library PrismStructs {
    // @dev RouteGroup represent A->B->C..->D swap. That is, through multiple HopPaths
    struct RouteGroup {
        uint256 percent;
        HopPath[] paths;
    }

    // @dev HopPath Represents a swap from A->B, which does not involve an intermediate path, but may split the funds and use multiple dex
    // fromToken is obtained through RouteGroup
    struct HopPath {
        address toToken;
        Adapter[] adapters;
    }

    struct Adapter {
        address payable adapter;
        uint256 percent;
        SwapStep[] swaps; // They are all SwapSteps from A->B, but different dex
    }

    // @dev SwapStep Represents a swap from A->B through a specific dex, without involving intermediate paths.
    struct SwapStep {
        uint256 percent;
        uint256 swapType;
        bytes data;
    }

    struct UniswapV3Data {
        address router;
        uint160 sqrtX96;
        uint24 fee;
    }
}
