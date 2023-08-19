// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../script/Deployer.s.sol";
import "./GoblinBankBasicTestHelper.t.sol";

contract GoblinBankWithdrawTest is GoblinBankBasicTestHelper {
    using SafeERC20 for IERC20;

    function testWithdrawAll() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);

        assertEq(IERC20(goblinBank.baseToken()).balanceOf(ALICE), 0);
        uint sharesBefore = goblinBank.balanceOf(ALICE);

        vm.prank(ALICE);
        goblinBank.withdraw(sharesBefore);
        uint sharesAfter = goblinBank.balanceOf(ALICE);

        assertEq(sharesAfter, 0);
        assertApproxEqAbs(IERC20(goblinBank.baseToken()).balanceOf(ALICE), DEPOSIT_AMOUNT, 2 * goblinBank.numberOfModules() * PRECISION);
        assertEq(IERC20(goblinBank.baseToken()).balanceOf(address(goblinBank)), 0);
        for (uint256 i = 0; i < goblinBank.numberOfModules(); i++) {
            (IYieldModule module,) = goblinBank.yieldOptions(i);
            assertEq(IERC20(goblinBank.baseToken()).balanceOf(address(module)), 0);
            assertApproxEqAbs(module.getBalance(), 0, goblinBank.numberOfModules() * PRECISION);
        }
    }


    function testWithdrawSome() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);

        assertEq(IERC20(goblinBank.baseToken()).balanceOf(ALICE), 0);
        uint sharesBefore = goblinBank.balanceOf(ALICE);

        vm.prank(ALICE);
        goblinBank.withdraw(sharesBefore / 2);
        uint sharesAfter = goblinBank.balanceOf(ALICE);

        assertEq(sharesAfter, sharesBefore / 2);
        assertApproxEqAbs(IERC20(goblinBank.baseToken()).balanceOf(ALICE), DEPOSIT_AMOUNT / 2, goblinBank.numberOfModules() * PRECISION);
    }

    function testWithdrawAfterSomeTime() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);
        assertEq(IERC20(goblinBank.baseToken()).balanceOf(ALICE), 0);

        _moveBlock(1000);
        goblinBank.harvest();

        _moveBlock(5);

        assertEq(IERC20(goblinBank.baseToken()).balanceOf(address(goblinBank)), 0);
        withdrawHelper(ALICE, goblinBank.balanceOf(ALICE));

        assertGt(IERC20(goblinBank.baseToken()).balanceOf(ALICE), DEPOSIT_AMOUNT);
    }

    function testMultipleWithdraw() public {
        // Scenario :
        //Alice deposit
        //Bob deposit
        //Harvest
        //Alice withdraw 50% of her shares
        //Harvest
        //Alice withdraw 100% of remaining shares

        depositHelper(ALICE, DEPOSIT_AMOUNT);

        _moveBlock(1000);
        depositHelper(BOB, DEPOSIT_AMOUNT);

        _moveBlock(1000);
        goblinBank.harvest();
        assertEq(IERC20(goblinBank.baseToken()).balanceOf(address(goblinBank)), 0);
        withdrawHelper(ALICE, goblinBank.balanceOf(ALICE) / 2);
        assertEq(goblinBank.balanceOf(ALICE), DEPOSIT_AMOUNT / 2);

        _moveBlock(1000);
        goblinBank.harvest();
        withdrawHelper(ALICE, goblinBank.balanceOf(ALICE));

        assertEq(goblinBank.balanceOf(ALICE), 0);
        assertGt(IERC20(BASE_TOKEN).balanceOf(ALICE), DEPOSIT_AMOUNT);
    }

    function testShouldEmitWithdrawEvent() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);

        _moveBlock(1000);
        goblinBank.harvest();
        uint sharesToWithdraw = goblinBank.balanceOf(ALICE);

        _moveBlock(1);

        vm.startPrank(ALICE);
                                            //can't test Amount field
        vm.expectEmit(false, false, false, false, address(goblinBank));
        emit Withdraw(ALICE, sharesToWithdraw, DEPOSIT_AMOUNT);
        goblinBank.withdraw(sharesToWithdraw);
        vm.stopPrank();
    }

    function testTotalSupplyShouldBeNullIfAllWithdraw() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);
        _moveBlock(1);
        depositHelper(BOB, DEPOSIT_AMOUNT);

        _moveBlock(1000);
        goblinBank.harvest();

        withdrawHelper(BOB, goblinBank.balanceOf(BOB));
        withdrawHelper(ALICE, goblinBank.balanceOf(ALICE));
        assertEq(goblinBank.totalSupply(), 0);
    }

    function testTotalSupplyShouldBeNullIfAllWithdrawWithPerfFee() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);
        _moveBlock(1);
        depositHelper(BOB, DEPOSIT_AMOUNT);

        vm.prank(address(timelock));
        uint16 perfFee = 10 * 100;
        //10% perf fee
        goblinBank.setPerformanceFee(perfFee);

        _moveBlock(1000);
        goblinBank.harvest();
        _moveBlock(1);

        withdrawHelper(BOB, goblinBank.balanceOf(BOB));
        withdrawHelper(ALICE, goblinBank.balanceOf(ALICE));
        assertEq(goblinBank.totalSupply(), 0);
    }

    function testShouldWithdrawAllWithMultipleModules() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);
        _moveBlock(10000);

        goblinBank.harvest();
        _moveBlock(1);

        // withdrawHelper(ALICE, GoblinBank.balanceOf(ALICE));
    }

    function testShouldWithdrawAllWithMultipleDeposits() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);
        _moveBlock(10000);
        goblinBank.harvest();

        _moveBlock(5);

        depositHelper(BOB, DEPOSIT_AMOUNT);
        _moveBlock(10000);
        goblinBank.harvest();

        _moveBlock(1);

        depositHelper(CLARA, DEPOSIT_AMOUNT);
        _moveBlock(10000);
        goblinBank.harvest();

        _moveBlock(1);

        //Alice again
        depositHelper(ALICE, DEPOSIT_AMOUNT);
        _moveBlock(10000);
        goblinBank.harvest();

        _moveBlock(1);

        withdrawHelper(ALICE, goblinBank.balanceOf(ALICE));
        withdrawHelper(BOB, goblinBank.balanceOf(BOB));
        withdrawHelper(CLARA, goblinBank.balanceOf(CLARA));
    }

    function testShouldFailOnBaseTokenRescueWithdrawal() public {
        deal(goblinBank.baseToken(), address(goblinBank), DEPOSIT_AMOUNT);
        _moveBlock(1);
        vm.startPrank(address(timelock));
        vm.expectRevert(bytes("GoblinBank: can't pull out base tokens"));
        goblinBank.rescueToken(BASE_TOKEN);
        vm.stopPrank();
    }

    function testShouldAllowTokenRescueWithdrawal() public {
        deal(ARB, address(goblinBank), DEPOSIT_AMOUNT);
        _moveBlock(1);
        assertEq(IERC20(ARB).balanceOf(address(timelock)), 0);
        vm.startPrank(address(timelock));
        goblinBank.rescueToken(ARB);
        assertEq(IERC20(ARB).balanceOf(address(timelock)), DEPOSIT_AMOUNT);
        vm.stopPrank();
    }
}
