// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GoblinBankBasicTestHelper.t.sol";

contract GoblinBankStressTest is GoblinBankBasicTestHelper {

    function testStressTestDepositInSameBlock() public {
        vm.prank(address(timelock));
        goblinBank.setCap(DEPOSIT_AMOUNT * 1000);
        for (uint256 i = 420; i < 520; i++) {
            address addr = address(uint160(i));
            depositAndCheckPPS(addr);
            assertEq(IERC20(BASE_TOKEN).balanceOf(addr), 0);
            assertApproxEqAbs(goblinBank.balanceOf(addr), DEPOSIT_AMOUNT, PRECISION);
        }
    }

    function testStressTestDepositInDifferentBlock() public {
        vm.prank(address(timelock));
        goblinBank.setCap(DEPOSIT_AMOUNT * 1000);
        for (uint256 i = 420; i < 520; i++) {
            _moveBlock(1);
            address addr = address(uint160(i));
            depositAndCheckPPS(addr);
            assertEq(IERC20(BASE_TOKEN).balanceOf(addr), 0);
            assertApproxEqAbs(goblinBank.balanceOf(addr), DEPOSIT_AMOUNT, PRECISION * i);
        }
    }

    function testStressTestWithdrawInSameBlock() public {
        testStressTestDepositInSameBlock();
        _moveBlock(1);

        for (uint256 i = 420; i < 520; i++) {
            address addr = address(uint160(i));
            uint256 shares = goblinBank.balanceOf(addr);
            withdrawHelper(addr, shares);
            assertApproxEqAbs(IERC20(BASE_TOKEN).balanceOf(addr), DEPOSIT_AMOUNT, PRECISION * 2);
            assertEq(goblinBank.balanceOf(addr), 0);
        }
    }

    function testStressTestWithdrawInDifferentBlock() public {
        testStressTestDepositInDifferentBlock();
        _moveBlock(1);

        for (uint256 i = 420; i < 520; i++) {
            _moveBlock(1);
            address addr = address(uint160(i));
            uint256 shares = goblinBank.balanceOf(addr);
            withdrawHelper(addr, shares);
            assertGt(IERC20(BASE_TOKEN).balanceOf(addr), DEPOSIT_AMOUNT - PRECISION);
            assertEq(goblinBank.balanceOf(addr), 0);
        }
    }

    function testStressDepositWithdrawInSameBlock() public {
        for (uint256 i = 420; i < 520; i++) {
            address addr = address(uint160(i));
            depositHelper(addr, DEPOSIT_AMOUNT);
            assertEq(IERC20(BASE_TOKEN).balanceOf(addr), 0);
            assertEq(goblinBank.balanceOf(addr), DEPOSIT_AMOUNT);
            uint256 shares = goblinBank.balanceOf(addr);
            withdrawHelper(addr, shares);
            assertApproxEqAbs(IERC20(BASE_TOKEN).balanceOf(addr), DEPOSIT_AMOUNT, PRECISION);
            assertEq(goblinBank.balanceOf(addr), 0);
        }
    }

    function testStressDepositWithdrawInDifferentBlock() public {
        for (uint256 i = 420; i < 520; i++) {
            address addr = address(uint160(i));
            depositHelper(addr, DEPOSIT_AMOUNT);
            assertEq(IERC20(BASE_TOKEN).balanceOf(addr), 0);
            assertEq(goblinBank.balanceOf(addr), DEPOSIT_AMOUNT);
            _moveBlock(1);
            withdrawHelper(addr, DEPOSIT_AMOUNT);
            assertApproxEqAbs(IERC20(BASE_TOKEN).balanceOf(addr), DEPOSIT_AMOUNT, PRECISION);
            assertEq(goblinBank.balanceOf(addr), 0);
        }
    }

    function testStressDepositHarvestWithdraw() public {
        for (uint256 i = 420; i < 520; i++) {
            address addr = address(uint160(i));
            depositHelper(addr, DEPOSIT_AMOUNT);
            assertEq(IERC20(BASE_TOKEN).balanceOf(addr), 0);
            assertEq(goblinBank.balanceOf(addr), DEPOSIT_AMOUNT);
            _moveBlock(1000);
            goblinBank.harvest();
            _moveBlock(10);
            withdrawHelper(addr, DEPOSIT_AMOUNT);
            assertGt(IERC20(BASE_TOKEN).balanceOf(addr), DEPOSIT_AMOUNT);
            assertEq(goblinBank.balanceOf(addr), 0);
        }
    }

    function depositAndCheckPPS(address addr) private {
        //We test lastUpdatedPricePerShare because it takes into account all the deposits, not the shares
        //We use lastUpdatedPricePerShare inside deposit
        uint lastPpsBefore = goblinBank.lastUpdatedPricePerShare();
        uint ppsBefore = goblinBank.pricePerShare();
        depositHelper(addr, DEPOSIT_AMOUNT);
        uint lastPpsAfter = goblinBank.lastUpdatedPricePerShare();
        uint ppsAfter = goblinBank.pricePerShare();

        //If harvest, should increase
        //If nothing to harvest, should stay the same
        assertGe(lastPpsAfter, ppsAfter);
        assertGe(lastPpsBefore, ppsBefore);

    }
}
