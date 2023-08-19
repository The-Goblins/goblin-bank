// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CompoundV3BaseTest.t.sol";

contract CompoundV3HarvestTest is CompoundV3BaseTest {

    function testCanHarvest() public {
        uint256 lastPricePerShare = yieldModule.lastUpdatedBalance();
        _deposit(address(goblinBank), SMALL_AMOUNT);
        _moveBlock(1000);
        _harvest(address(goblinBank), address(goblinBank));
        uint256 currentPricePerShare = yieldModule.lastUpdatedBalance();

        assertApproxEqAbs(yieldModule.getBalance(), SMALL_AMOUNT, PRECISION);
        assertEq(IERC20(yieldModule.baseToken()).balanceOf(address(yieldModule)), 0);
        assertGt(IERC20(yieldModule.baseToken()).balanceOf(address(goblinBank)), 0);
        assertGt(currentPricePerShare, lastPricePerShare);
    }

    function testOnlyGoblinBankCanHarvest() public {
        _deposit(address(goblinBank), SMALL_AMOUNT);
        _moveBlock(1000);
        _harvest(address(goblinBank), address(goblinBank));
        _moveBlock(1000);

        vm.prank(RANDOM_ADDRESS);
        vm.expectRevert("BaseModule: only vault");
        yieldModule.harvest(address(goblinBank));
    }

    function testOwnerCannotHarvest() public {
        vm.prank(OWNER);
        vm.expectRevert("BaseModule: only vault");
        yieldModule.harvest(address(goblinBank));
    }

    function testManagerCannotHarvest() public {
        vm.prank(MANAGER);
        vm.expectRevert("BaseModule: only vault");
        yieldModule.harvest(address(goblinBank));
    }

    function testHarvestEmitEvent() public {
        _deposit(address(goblinBank), SMALL_AMOUNT);
        _moveBlock(1000);

        vm.startPrank(address(goblinBank));
        vm.expectEmit(false, false, false, false);
        emit Harvest(yieldModule.baseToken(), 0);
        yieldModule.harvest(address(goblinBank));
        vm.stopPrank();
    }

    function testCanHarvestEvenIfLastPricePerShareEqualCurrentPricePerShare() public {
        _deposit(address(goblinBank), SMALL_AMOUNT);
        _harvest(address(goblinBank), RANDOM_ADDRESS);
        // The second harvest should never revert because of : "CompoundV3: module not profitable"
        _harvest(address(goblinBank), RANDOM_ADDRESS);
    }

    function testBalanceGrowsOverTime() public {
        _deposit(address(goblinBank), SMALL_AMOUNT);
        uint balance0 = yieldModule.getBalance();
        _moveBlock(1000);
        uint balance1 = yieldModule.getBalance();
        _moveBlock(1000);
        uint balance2 = yieldModule.getBalance();
        assertGt(balance1, balance0);
        assertGt(balance2, balance1);
    }

    function testHarvestKeepsLastUpdatedBalanceAtSameLevel() public {
        _deposit(address(goblinBank), SMALL_AMOUNT);
        _moveBlock(1000);
        uint balance1 = yieldModule.lastUpdatedBalance();
        _harvest(address(goblinBank), RANDOM_ADDRESS);
        uint balance2 = yieldModule.lastUpdatedBalance();
        assertEq(balance1, balance2);
    }
}
