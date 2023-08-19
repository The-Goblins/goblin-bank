// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CompoundV3BaseTest.t.sol";

contract CompoundV3DepositTest is CompoundV3BaseTest {

    function testCanDeposit() public {
        _deposit(address(goblinBank), SMALL_AMOUNT);

        assertApproxEqAbs(yieldModule.getBalance(), SMALL_AMOUNT, PRECISION);
        assertEq(IERC20(yieldModule.baseToken()).balanceOf(address(yieldModule)), 0);
        assertEq(IERC20(yieldModule.baseToken()).balanceOf(address(goblinBank)), 0);
    }

    function testCanDepositNative() public {
        BASE_TOKEN = USDC;
        COMPOUND_V3_COMET_TOKEN = COMPOUND_V3_USDC;
        PRECISION = 10**9;
        deployCompoundV3YieldModule(address(goblinBank), address(uniV3));
        yieldModule = compoundV3YieldModule;

        deal(USDC, address(goblinBank), SMALL_AMOUNT);
        vm.startPrank(address(goblinBank));
        IERC20(yieldModule.baseToken()).approve(address(yieldModule), SMALL_AMOUNT);
        yieldModule.deposit(SMALL_AMOUNT);
        vm.stopPrank();

        assertApproxEqAbs(yieldModule.getBalance(), SMALL_AMOUNT, PRECISION);
        assertEq(IERC20(yieldModule.baseToken()).balanceOf(address(yieldModule)), 0);
        assertEq(IERC20(yieldModule.baseToken()).balanceOf(address(goblinBank)), 0);
    }

    function testOnlyGoblinBankCanDeposit() public {
        _deposit(address(goblinBank), SMALL_AMOUNT);

        vm.prank(RANDOM_ADDRESS);
        vm.expectRevert("BaseModule: only vault");
        yieldModule.deposit(SMALL_AMOUNT);
    }

    function testOwnerCannotDeposit() public {
        vm.prank(OWNER);
        vm.expectRevert("BaseModule: only vault");
        yieldModule.deposit(SMALL_AMOUNT);
    }

    function testManagerCannotDeposit() public {
        vm.prank(MANAGER);
        vm.expectRevert("BaseModule: only vault");
        yieldModule.deposit(SMALL_AMOUNT);
    }

    function testDepositAmountCannotBeZero() public {
        vm.prank(address(goblinBank));
        vm.expectRevert("CompoundV3: deposit amount cannot be zero");
        yieldModule.deposit(0);
    }

    function testDepositEmitEvent() public {
        deal(yieldModule.baseToken(), address(goblinBank), SMALL_AMOUNT);
        vm.startPrank(address(goblinBank));
        IERC20(yieldModule.baseToken()).approve(address(yieldModule), SMALL_AMOUNT);
        vm.expectEmit(false, false, false, true);
        emit Deposit(yieldModule.baseToken(), SMALL_AMOUNT);
        yieldModule.deposit(SMALL_AMOUNT);
        vm.stopPrank();
    }
}
