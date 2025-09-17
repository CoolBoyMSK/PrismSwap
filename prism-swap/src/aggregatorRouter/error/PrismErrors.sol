// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

library PrismErrors {
    error AdapterExists();
    error AdapterDoesNotExist();
    error AdapterAddressZero();
    error IncorrectFeeReceiver();
    error FeeRateTooBig();
    error TokenPairInvalid();
    error IncorrectMsgValue();
    error SlippageLimitExceeded();
    error DelegatecallFailed();
    error Forbidden();
    error AdapterNotApproved();
}
