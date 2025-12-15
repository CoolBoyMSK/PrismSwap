// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../../src/aggregatorRouter/PrismProxy.sol";
import "../../src/aggregatorRouter/error/PrismErrors.sol";

contract MockAdapter {
    // add this to be excluded from coverage report
    function test() public {}
    function failWithoutData() external pure {
        revert();
    }
}

contract PrismProxyTest is Test {
    // add this to be excluded from coverage report
    function test() public {}

    PrismProxy public swapProxy;
    address public hubContract;
    address public user;
    address public adapter;
    MockAdapter public mockAdapter;

    function setUp() public {
        hubContract = makeAddr("hubContract");
        user = makeAddr("user");
        adapter = makeAddr("adapter");
        mockAdapter = new MockAdapter();

        vm.prank(hubContract);
        swapProxy = new PrismProxy();
    }

    function test_Swap_WithZeroAddressAdapter() public {
        bytes memory data = abi.encodeWithSignature("someFunction()");

        vm.prank(hubContract);
        vm.expectRevert(PrismErrors.AdapterNotApproved.selector);
        spender.swap(address(0), data);
    }

    function test_Swap_WithValidAdapter() public {
        bytes memory data = abi.encodeWithSignature("someFunction()");

        vm.prank(hubContract);
        spender.swap(adapter, data);
    }

    function test_Swap_WithEmptyRevertData() public {
        bytes memory data = abi.encodeWithSignature("failWithoutData()");

        vm.prank(hubContract);
        vm.expectRevert("ADAPTER_DELEGATECALL_FAILED");
        spender.swap(address(mockAdapter), data);
    }
}
