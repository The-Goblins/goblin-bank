// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AaveBaseTest.t.sol";

contract AaveGetterTest is AaveBaseTest {

    function testCanGetBalance() public {
        assertEq(aaveYieldModule.getLastUpdatedBalance(), 0);
        assertEq(aaveYieldModule.getBalance(), 0);
        _deposit(address(goblinBank), SMALL_AMOUNT);
        assertApproxEqAbs(aaveYieldModule.getLastUpdatedBalance(), SMALL_AMOUNT, 1);
        assertApproxEqAbs(aaveYieldModule.getBalance(), SMALL_AMOUNT, 1);
        _moveBlock(10000);
        assertGe(aaveYieldModule.getLastUpdatedBalance(), SMALL_AMOUNT);
        assertGe(aaveYieldModule.getBalance(), SMALL_AMOUNT);
        _harvest(address(goblinBank), address(goblinBank));
        assertApproxEqAbs(aaveYieldModule.getLastUpdatedBalance(), SMALL_AMOUNT, 1);
        assertApproxEqAbs(aaveYieldModule.getBalance(), SMALL_AMOUNT, 1);
        uint256 profit = IERC20(aaveYieldModule.baseToken()).balanceOf(address(goblinBank));
        _deposit(address(goblinBank), profit);
        assertApproxEqAbs(aaveYieldModule.getLastUpdatedBalance(), SMALL_AMOUNT + profit, 1);
        assertApproxEqAbs(aaveYieldModule.getBalance(), SMALL_AMOUNT + profit, 1);
        _withdraw(address(goblinBank), ALL_SHARE_AS_FRACTION, ALICE);
        assertApproxEqAbs(aaveYieldModule.getLastUpdatedBalance(), 0, 1);
        assertApproxEqAbs(aaveYieldModule.getBalance(), 0, 1);
    }

    function testCanGetExectionFee() public {
        assertEq(aaveYieldModule.getExecutionFee(0), 0);
        assertEq(aaveYieldModule.getExecutionFee(SMALL_AMOUNT), 0);
        assertEq(aaveYieldModule.getExecutionFee(BIG_AMOUNT), 0);
    }
}
