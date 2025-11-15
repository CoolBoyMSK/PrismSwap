// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../library/PrismStructs.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IExecutor {
    /**
     * @notice Execute a mega swap
     * @param fromToken The address of the token to swap from
     * @param toToken The address of the token to swap to
     * @param paths The array of paths to swap
     */
    function executeSplitSwap(IERC20 fromToken, IERC20 toToken, PrismStructs.RouteGroup[] calldata paths) external payable;

    function setDEXAdapter(address _adapter, bool isAdd) external;

    function getProviders() external view returns (address[] memory);
}
