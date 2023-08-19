// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../script/Deployer.s.sol";
import "./GoblinBankBasicTestHelper.t.sol";

contract GoblinBankRandomScenarioTest is GoblinBankBasicTestHelper
{
    using SafeERC20 for IERC20;

    function testShouldDepositAndWithdrawInSameBlock() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);
        withdrawHelper(ALICE, goblinBank.balanceOf(ALICE));

        assertApproxEqAbs(
            IERC20(goblinBank.baseToken()).balanceOf(ALICE),
            DEPOSIT_AMOUNT,
            2 * goblinBank.numberOfModules() * PRECISION
        );
        assertEq(goblinBank.balanceOf(ALICE), 0);
    }

    function testBobShouldNotBeAbleToSandwitchPanic() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);
        _waitAndHarvest();

        depositHelper(BOB, DEPOSIT_AMOUNT);

        vm.startPrank(address(timelock));
        goblinBank.panic();
        goblinBank.finishPanic();
        vm.stopPrank();

        withdrawHelper(BOB, goblinBank.balanceOf(BOB));
        assertLe(
            IERC20(goblinBank.baseToken()).balanceOf(BOB),
            DEPOSIT_AMOUNT
        );

        withdrawHelper(ALICE, goblinBank.balanceOf(ALICE));
        assertGt(
            IERC20(goblinBank.baseToken()).balanceOf(ALICE),
            DEPOSIT_AMOUNT
        );
    }

    function testAliceShouldNotBeAbleToSandwichBobAndStealFunds() public {
        vm.startPrank(ALICE);
        deal(BASE_TOKEN, ALICE, 2);
        IERC20(BASE_TOKEN).safeApprove(address(goblinBank), type(uint256).max);
        vm.expectRevert("GoblinBank: amount too small");
        goblinBank.deposit(2);
        deal(BASE_TOKEN, address(goblinBank), DEPOSIT_AMOUNT + 2);
        vm.stopPrank();

        depositHelper(BOB, DEPOSIT_AMOUNT);

        uint256 shares = goblinBank.balanceOf(ALICE);
        vm.prank(ALICE);
        vm.expectRevert("GoblinBank: withdraw can't be 0");
        goblinBank.withdraw(shares);

        withdrawHelper(BOB, goblinBank.balanceOf(BOB));
        assertEq(
            IERC20(goblinBank.baseToken()).balanceOf(ALICE),
            2
        );
        assertApproxEqAbs(
            IERC20(goblinBank.baseToken()).balanceOf(BOB),
            DEPOSIT_AMOUNT, PRECISION
        );
    }

    function testShouldDepositSetModuleWithdraw() public {
        (IYieldModule lastModule, uint256 allocationLastModule) = goblinBank
            .yieldOptions(goblinBank.numberOfModules() - 1);

        vm.startPrank(address(timelock));
        goblinBank.pause();
        goblinBank.removeModule(goblinBank.numberOfModules() - 1);
        uint256[] memory allocations = new uint256[](
            goblinBank.numberOfModules()
        );
        for (uint256 i = 0; i < goblinBank.numberOfModules(); i++) {
            (, uint256 allocation) = goblinBank.yieldOptions(i);
            allocations[i] = allocation;
        }
        allocations[
            goblinBank.numberOfModules() - 1
        ] += allocationLastModule;
        goblinBank.setModuleAllocation(allocations);
        goblinBank.unpause();
        vm.stopPrank();

        depositHelper(ALICE, DEPOSIT_AMOUNT);
        _waitAndHarvest();

        _moveBlock(5);

        vm.startPrank(address(timelock));
        goblinBank.panic();
        goblinBank.addModule(lastModule);
        allocations = new uint256[](goblinBank.numberOfModules());
        for (uint256 i = 0; i < goblinBank.numberOfModules(); i++) {
            (, uint256 allocation) = goblinBank.yieldOptions(i);
            allocations[i] = allocation;
        }
        allocations[
            goblinBank.numberOfModules() - 2
        ] -= allocationLastModule;
        allocations[
            goblinBank.numberOfModules() - 1
        ] += allocationLastModule;
        goblinBank.setModuleAllocation(allocations);
        goblinBank.finishPanic();
        vm.stopPrank();

        _moveBlock(5);

        depositHelper(BOB, DEPOSIT_AMOUNT);

        _waitAndHarvest();

        withdrawHelper(ALICE, goblinBank.balanceOf(ALICE) / 2);
        withdrawHelper(BOB, goblinBank.balanceOf(BOB) / 2);

        assertGt(
            IERC20(goblinBank.baseToken()).balanceOf(ALICE),
            DEPOSIT_AMOUNT / 2
        );
        assertGt(
            IERC20(goblinBank.baseToken()).balanceOf(BOB),
            DEPOSIT_AMOUNT / 2
        );
        assertGt(
            IERC20(goblinBank.baseToken()).balanceOf(ALICE),
            IERC20(goblinBank.baseToken()).balanceOf(BOB)
        );

        _waitAndHarvest();

        _moveBlock(5);

        withdrawHelper(ALICE, goblinBank.balanceOf(ALICE));
        withdrawHelper(BOB, goblinBank.balanceOf(BOB));

        assertEq(goblinBank.balanceOf(ALICE), 0);
        assertEq(goblinBank.balanceOf(BOB), 0);

        assertGt(
            IERC20(goblinBank.baseToken()).balanceOf(ALICE),
            DEPOSIT_AMOUNT
        );
        assertGt(
            IERC20(goblinBank.baseToken()).balanceOf(BOB),
            DEPOSIT_AMOUNT
        );
        assertGt(
            IERC20(goblinBank.baseToken()).balanceOf(ALICE),
            IERC20(goblinBank.baseToken()).balanceOf(BOB)
        );
    }

    function testAllocationShouldBeCorrectAfterHarvest() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);

        for (uint256 i = 0; i < goblinBank.numberOfModules(); i++) {
            (IYieldModule module, uint256 allocation) = goblinBank
                .yieldOptions(i);
            assertApproxEqAbs(
                module.getBalance(),
                (DEPOSIT_AMOUNT * allocation) / goblinBank.MAX_BPS(),
                goblinBank.numberOfModules() * PRECISION
            );
        }

        _moveBlock(10000000);

        uint256[] memory amounts = new uint256[](
            goblinBank.numberOfModules()
        );
        bool test = false;
        for (uint256 i = 0; i < goblinBank.numberOfModules(); i++) {
            (IYieldModule module, uint256 allocation) = goblinBank
                .yieldOptions(i);
            amounts[i] =
                (module.getBalance() * goblinBank.MAX_BPS()) /
                allocation;
            for (uint256 j = 0; j < i; j++) {
                if (amounts[j] > amounts[i]) {
                    // If imbalance we set test to true
                    if (amounts[j] - amounts[i] > 1000) {
                        test = true;
                    }
                } else {
                    if (amounts[i] - amounts[j] > 1000) {
                        test = true;
                    }
                }
            }
        }
        assertTrue(test);

        uint256 profit = goblinBank.harvest();

        for (uint256 i = 0; i < goblinBank.numberOfModules(); i++) {
            (IYieldModule module, uint256 allocation) = goblinBank
                .yieldOptions(i);
            assertApproxEqAbs(
                module.getBalance(),
                ((DEPOSIT_AMOUNT + profit) * allocation) /
                    goblinBank.MAX_BPS(),
                goblinBank.numberOfModules() * PRECISION
            );
        }
    }

    function testWhaleShouldWithdrawEvenWithShrimp() public {
        uint256 whaleAmount;
        // Needed to avoid reaching max cap on aave with 18 decimals token
        if (IERC20Metadata(goblinBank.baseToken()).decimals() == 18) {
            whaleAmount = DEPOSIT_AMOUNT;
        }
        if (IERC20Metadata(goblinBank.baseToken()).decimals() == 6) {
            whaleAmount = 1e11;
        } else {
            whaleAmount = BIG_DEPOSIT_AMOUNT;
        }
        uint256 bobAmount = SM_MIN_AMOUNT;

        //double cap of strat to deposit whaleAmount
        vm.prank(address(timelock));
        goblinBank.setCap(BIG_DEPOSIT_AMOUNT * 2);

        depositHelper(ALICE, whaleAmount);
        depositHelper(BOB, bobAmount);

        _moveBlock(10);
        uint profit = goblinBank.harvest();

        _moveBlock(1000000);

        deal(ALICE, 300000000000000000);
        uint shares = goblinBank.balanceOf(ALICE);
        vm.prank(ALICE);
        goblinBank.withdraw{value : 300000000000000000}(shares);
        uint aliceBalanceWithoutStargateFunds =  IERC20(BASE_TOKEN).balanceOf(ALICE);
        deal(BASE_TOKEN, ALICE, aliceBalanceWithoutStargateFunds + whaleAmount * STARGATE_ALLOCATION / MAX_BPS);
        withdrawHelper(BOB, goblinBank.balanceOf(BOB));

        assertEq(goblinBank.balanceOf(ALICE), 0);
        assertGt(IERC20(goblinBank.baseToken()).balanceOf(ALICE), whaleAmount);
        assertGt(IERC20(goblinBank.baseToken()).balanceOf(BOB), bobAmount);
    }

    function _waitAndHarvest() public {
        _moveBlock(10000);
        goblinBank.harvest();
    }

    function _addStargateAndSetAllocation() public {
        vm.startPrank(address(timelock));
        addStargateToGoblinBank(stargateYieldModule);
        uint256[] memory moduleAllocations = new uint256[](2);
        moduleAllocations[0] = goblinBank.MAX_BPS() / 2;
        moduleAllocations[1] = goblinBank.MAX_BPS() / 2;

        goblinBank.setModuleAllocation(moduleAllocations);
        vm.stopPrank();
    }
}
