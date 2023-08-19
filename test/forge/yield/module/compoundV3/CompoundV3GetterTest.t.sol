// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CompoundV3BaseTest.t.sol";

contract CompoundV3GetterTest is CompoundV3BaseTest {

    function testCanGetBalance() public {
        assertEq(yieldModule.getLastUpdatedBalance(), 0);
        assertEq(yieldModule.getBalance(), 0);
        _deposit(address(goblinBank), SMALL_AMOUNT);
        assertApproxEqAbs(yieldModule.getLastUpdatedBalance(), SMALL_AMOUNT, PRECISION);
        assertApproxEqAbs(yieldModule.getBalance(), SMALL_AMOUNT, PRECISION);
        _moveBlock(1000);

        //IOU Last updated balance should not move if no harvest / deposits
        assertGe(yieldModule.getLastUpdatedBalance(), SMALL_AMOUNT);

        //IOU balance grows with time on Compound V3
        assertGt(yieldModule.getBalance(), SMALL_AMOUNT);


        //Not compounded yet
        _harvest(address(goblinBank), address(goblinBank));
        assertApproxEqAbs(yieldModule.getLastUpdatedBalance(), SMALL_AMOUNT, PRECISION);
        assertApproxEqAbs(yieldModule.getBalance(), SMALL_AMOUNT, PRECISION);
        uint256 profit = IERC20(yieldModule.baseToken()).balanceOf(address(goblinBank));
        _deposit(address(goblinBank), profit);

        assertApproxEqAbs(yieldModule.getLastUpdatedBalance(), SMALL_AMOUNT + profit, PRECISION);
        assertApproxEqAbs(yieldModule.getBalance(), SMALL_AMOUNT + profit, PRECISION);
        _withdraw(address(goblinBank), ALL_SHARE_AS_FRACTION, ALICE);
        assertApproxEqAbs(yieldModule.getLastUpdatedBalance(), 0, PRECISION);
        assertEq(yieldModule.getBalance(), 0);
    }

    function testCanGetExectionFee() public {
        assertEq(yieldModule.getExecutionFee(0), 0);
        assertEq(yieldModule.getExecutionFee(SMALL_AMOUNT), 0);
        assertEq(yieldModule.getExecutionFee(BIG_AMOUNT), 0);
    }
}
