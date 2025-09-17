// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../library/PrismAdmin.sol";
import "../library/UniversalERC20.sol";
import "../library/SignedDecimalMath.sol";
import "./PrismProxy.sol";

/**
 * @title PrismHub
 * @notice A DEX router supporting multiple aggregators with fee management
 * @dev Key features:
 * - Multi-aggregator support through adapter pattern
 * - Configurable fees on input/output tokens
 * - Support for both ERC20 and ETH swaps
 * - Admin controlled with pause mechanism
 * - Protected against reentrancy
 * - Slippage protection
 *
 * Flow: validate -> charge input fee (if any) -> swap -> 
 * verify slippage -> charge output fee (if any) -> transfer to user
 */
contract PrismHub is ReentrancyGuard, PrismAdmin {
    using SignedDecimalMath for uint256;
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;

    struct Adapter {
        address addr;
        bool isRegistered;
        bytes4 selector;
    }

    struct TradeParams {
        string providerId;
        address fromToken;
        uint256 fromTokenAmount;
        address toToken;
        uint256 minAmountOut;
        uint256 feeRate;
        bool feeOnFromToken;
        address feeReceiver;
        bytes data;
    }

    uint256 public maxFeeRate;
    PrismProxy public immutable swapProxy;
    mapping(string providerId => Adapter) public adapters;
    address[] public registeredProviders;

    event ProviderRegistered(string indexed providerId, address indexed addr, bytes4 selector);
    event ProviderRemoved(string indexed providerId);
    event Swap(
        string indexed providerId,
        address sender,
        address fromToken,
        uint256 fromTokenAmount,
        address toToken,
        uint256 toTokenAmount,
        uint256 fee
    );

    constructor(address[3] memory _admins, uint256 _maxFeeRate) PrismAdmin(_admins) {
        maxFeeRate = _maxFeeRate;
        swapProxy = new PrismProxy();
    }

    function getProviders() external view returns (address[] memory) {
        return registeredProviders;
    }

    function registerProvider(string calldata providerId, address addr, bytes4 selector) external onlyAdmin {
        if (adapters[providerId].isRegistered) revert PrismErrors.AdapterExists();
        if (addr == address(0)) revert PrismErrors.AdapterAddressZero();
        for (uint256 i = 0; i < registeredProviders.length; i++) {
            if (registeredProviders[i] == addr) revert PrismErrors.AdapterExists();
        }

        Adapter storage adapter = adapters[providerId];
        adapter.addr = addr;
        adapter.selector = selector;
        adapter.isRegistered = true;
        registeredProviders.push(addr);
        emit ProviderRegistered(providerId, addr, selector);
    }

    function unregisterProvider(string calldata providerId) external onlyAdmin {
        if (!adapters[providerId].isRegistered) revert PrismErrors.AdapterDoesNotExist();

        address addr = adapters[providerId].addr;
        adapters[providerId].isRegistered = false;
        adapters[providerId].addr = address(0);
        adapters[providerId].selector = bytes4(0);
        for (uint256 i = 0; i < registeredProviders.length; i++) {
            if (registeredProviders[i] == addr) {
                registeredProviders[i] = registeredProviders[registeredProviders.length - 1];
                registeredProviders.pop();
                break;
            }
        }
        emit ProviderRemoved(providerId);
    }

    /**
     * @dev Performs a swap
     */
    function swap(TradeParams memory params) external payable whenNotPaused nonReentrant {
        _swap(params);
    }

    function _swap(TradeParams memory params) internal {
        Adapter storage adapter = adapters[params.providerId];

        // 1. check params
        _validateSwapParams(params, adapter);

        uint256 feeAmount;
        uint256 receivedAmount;

        // 2. charge fee on fromToken if needed
        if (params.feeOnFromToken) {
            (params.fromTokenAmount, feeAmount) = _chargeFee(
                params.fromToken, params.feeOnFromToken, params.fromTokenAmount, params.feeRate, params.feeReceiver
            );
        }

        // 3. transfer fromToken
        if (params.fromToken != UniversalERC20.ETH) {
            IERC20(params.fromToken).safeTransferFrom(msg.sender, address(swapProxy), params.fromTokenAmount);
        }

        // 4. execute swap
        {
            uint256 balanceBefore = IERC20(params.toToken).universalBalanceOf(address(this));
            swapProxy.swap{value: params.fromToken == UniversalERC20.ETH ? params.fromTokenAmount : 0}(
                adapter.addr,
                abi.encodeWithSelector(
                    adapter.selector, params.fromToken, params.toToken, msg.sender, params.data
                )
            );
            receivedAmount = IERC20(params.toToken).universalBalanceOf(address(this)) - balanceBefore;
        }

        // 5. check slippage
        if (receivedAmount < params.minAmountOut) revert PrismErrors.SlippageLimitExceeded();

        // 6. charge fee on toToken if needed
        if (!params.feeOnFromToken) {
            (receivedAmount, feeAmount) =
                _chargeFee(params.toToken, params.feeOnFromToken, receivedAmount, params.feeRate, params.feeReceiver);
        }

        IERC20(params.toToken).universalTransfer(payable(msg.sender), receivedAmount);
        emit Swap(
            params.providerId,
            msg.sender,
            address(params.fromToken),
            params.fromTokenAmount,
            address(params.toToken),
            receivedAmount,
            feeAmount
        );
    }

    function _validateSwapParams(TradeParams memory params, Adapter storage adapter) internal view {
        if (params.feeReceiver == address(this)) revert PrismErrors.IncorrectFeeReceiver();
        if (params.feeRate > maxFeeRate) revert PrismErrors.FeeRateTooBig();
        if (params.fromToken == params.toToken) revert PrismErrors.TokenPairInvalid();
        if (!adapter.isRegistered) revert PrismErrors.AdapterDoesNotExist();
        if (msg.value != (params.fromToken == UniversalERC20.ETH ? params.fromTokenAmount : 0)) {
            revert PrismErrors.IncorrectMsgValue();
        }
    }

    function _chargeFee(address token, bool feeOnFromToken, uint256 amount, uint256 feeRate, address feeReceiver)
        internal
        returns (uint256, uint256)
    {
        uint256 feeAmount = amount.decimalMul(feeRate);
        if (feeRate > 0) {
            if (feeOnFromToken) {
                IERC20(token).universalTransferFrom(msg.sender, payable(feeReceiver), feeAmount);
            } else {
                IERC20(token).universalTransfer(payable(feeReceiver), feeAmount);
            }
        }
        return (amount -= feeAmount, feeAmount);
    }

    /// @notice Receive ETH
    receive() external payable {}
}
