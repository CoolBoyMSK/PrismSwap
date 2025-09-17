// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../library/UniversalERC20.sol";

contract MachaV2Adapter is ReentrancyGuard {
    address public immutable matchaApprover;
    address public immutable matchaRouter;

    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;

    constructor(address approver, address router) {
        matchaApprover = approver;
        matchaRouter = router;
    }

    function swapOnAdapter(
        address fromToken,
        address toToken,
        address recipient,
        bytes memory data
    ) external payable nonReentrant {
        uint256 fromTokenAmount = IERC20(fromToken).universalBalanceOf(address(this));
        if (fromToken != UniversalERC20.ETH) {
            // approve
            IERC20(fromToken).forceApprove(matchaApprover, fromTokenAmount);
            matchaRouter.functionCallWithValue(data, 0);
        } else {
            // For ETH, use fromTokenAmount instead of msg.value to handle fee deduction
            matchaRouter.functionCallWithValue(data, fromTokenAmount);
        }

        // transfer remaining tokens
        uint256 fromTokenBalance = IERC20(fromToken).universalBalanceOf(address(this));
        if (fromTokenBalance > 0) {
            IERC20(fromToken).universalTransfer(payable(recipient), fromTokenBalance);
        }

        uint256 toTokenBalance = IERC20(toToken).universalBalanceOf(address(this));
        if (toTokenBalance > 0) {
            IERC20(toToken).universalTransfer(payable(msg.sender), toTokenBalance);
        }
    }
}
