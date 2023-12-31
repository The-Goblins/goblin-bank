// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AaveBaseTest.t.sol";

contract AaveDepositTest is AaveBaseTest {

    function testCanDeposit() public {
        _deposit(address(goblinBank), SMALL_AMOUNT);
        assertEq(aaveYieldModule.getBalance(), SMALL_AMOUNT);
        assertEq(IERC20(aaveYieldModule.baseToken()).balanceOf(address(aaveYieldModule)), 0);
        assertEq(IERC20(aaveYieldModule.baseToken()).balanceOf(address(goblinBank)), 0);
    }

    function testOnlyGoblinBankCanDeposit() public {
        _deposit(address(goblinBank), SMALL_AMOUNT);

        vm.prank(RANDOM_ADDRESS);
        vm.expectRevert("BaseModule: only vault");
        aaveYieldModule.deposit(SMALL_AMOUNT);
    }

    function testOwnerCannotDeposit() public {
        vm.prank(OWNER);
        vm.expectRevert("BaseModule: only vault");
        aaveYieldModule.deposit(SMALL_AMOUNT);
    }

    function testManagerCannotDeposit() public {
        vm.prank(MANAGER);
        vm.expectRevert("BaseModule: only vault");
        aaveYieldModule.deposit(SMALL_AMOUNT);
    }

    function testDepositEmitEvent() public {
        deal(aaveYieldModule.baseToken(), address(goblinBank), SMALL_AMOUNT);
        vm.startPrank(address(goblinBank));
        IERC20(aaveYieldModule.baseToken()).approve(address(aaveYieldModule), SMALL_AMOUNT);
        vm.expectEmit(false, false, false, true);
        emit Deposit(aaveYieldModule.baseToken(), SMALL_AMOUNT);
        aaveYieldModule.deposit(SMALL_AMOUNT);
        vm.stopPrank();
    }
}
