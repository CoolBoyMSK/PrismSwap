// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

contract WethAddress {
    address public immutable WETH;

    constructor(address weth) {
        WETH = weth;
    }
}
