// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GoblinBankBasicTestHelper.t.sol";

contract GoblinBankRescue is GoblinBankBasicTestHelper {

    function testCanRescueToken() public {
        deal(ARB, address(goblinBank), DEPOSIT_AMOUNT);
        assertEq(IERC20(ARB).balanceOf(address(goblinBank)), DEPOSIT_AMOUNT);
        vm.startPrank(address(timelock));
        goblinBank.rescueToken(ARB);
        vm.stopPrank();
        assertEq(IERC20(ARB).balanceOf(address(goblinBank)), 0);
        assertEq(IERC20(ARB).balanceOf(address(timelock)), DEPOSIT_AMOUNT);
    }

    function testOnlyOwnerCanRescueToken() public {
        address token = ARB;
        vm.prank(RANDOM_ADDRESS);
        vm.expectRevert(bytes("AccessControl: account 0x305ad87a471f49520218feaf4146e26d9f068eb4 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"));
        goblinBank.rescueToken(token);
    }

    function testCanRescueNative() public {
        uint256 ownerBalanceBefore = address(timelock).balance;
        deal(address(goblinBank), DEPOSIT_AMOUNT);
        assertEq(address(goblinBank).balance, DEPOSIT_AMOUNT);
        vm.prank(address(timelock));
        goblinBank.rescueNative();
        assertEq(address(goblinBank).balance, 0);
        assertEq(address(timelock).balance - ownerBalanceBefore, DEPOSIT_AMOUNT);
    }

    function testOnlyOwnerCanRescueNative() public {
        vm.prank(RANDOM_ADDRESS);
        vm.expectRevert(bytes("AccessControl: account 0x305ad87a471f49520218feaf4146e26d9f068eb4 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"));
        goblinBank.rescueNative();
    }
}
