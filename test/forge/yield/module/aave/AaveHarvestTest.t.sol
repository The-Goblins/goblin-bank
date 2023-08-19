// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AaveBaseTest.t.sol";

contract AaveHarvestTest is AaveBaseTest {

    function testCanHarvest() public {
        uint256 lastPricePerShare = aaveYieldModule.lastPricePerShare();
        _deposit(address(goblinBank), SMALL_AMOUNT);
        _moveBlock(10000);
        _harvest(address(goblinBank), address(goblinBank));
        uint256 currentPricePerShare = aaveYieldModule.lastPricePerShare();

        assertApproxEqAbs(aaveYieldModule.getBalance(), SMALL_AMOUNT, 1);
        assertEq(IERC20(aaveYieldModule.baseToken()).balanceOf(address(aaveYieldModule)), 0);
        assertGt(IERC20(aaveYieldModule.baseToken()).balanceOf(address(goblinBank)), 0);
        assertGt(currentPricePerShare, lastPricePerShare);
    }

    function testOnlyGoblinBankCanHarvest() public {
        _deposit(address(goblinBank), SMALL_AMOUNT);
        _moveBlock(1000);
        _harvest(address(goblinBank), address(goblinBank));
        _moveBlock(1000);

        vm.prank(RANDOM_ADDRESS);
        vm.expectRevert("BaseModule: only vault");
        aaveYieldModule.harvest(address(goblinBank));
    }

    function testOwnerCannotHarvest() public {
        vm.prank(OWNER);
        vm.expectRevert("BaseModule: only vault");
        aaveYieldModule.harvest(address(goblinBank));
    }

    function testManagerCannotHarvest() public {
        vm.prank(MANAGER);
        vm.expectRevert("BaseModule: only vault");
        aaveYieldModule.harvest(address(goblinBank));
    }

    function testHarvestEmitEvent() public {
        _deposit(address(goblinBank), SMALL_AMOUNT);
        _moveBlock(1000);

        vm.startPrank(address(goblinBank));
        vm.expectEmit(false, false, false, false);
        emit Harvest(aaveYieldModule.baseToken(), 0);
        aaveYieldModule.harvest(address(goblinBank));
        vm.stopPrank();
    }

    function testCanHarvestEvenIfLastPricePerShareEqualCurrentPricePerShare() public {
        _deposit(address(goblinBank), SMALL_AMOUNT);
        _harvest(address(goblinBank), OWNER);
        // The second harvest should never revert because of : "Aave: module not profitable"
        _harvest(address(goblinBank), OWNER);
    }

    function testRevertIfModuleIsNotProfitable() public {
        _deposit(address(goblinBank), SMALL_AMOUNT);

        vm.mockCall(
            aaveYieldModule.pool(),
            abi.encodeWithSelector(IPoolAave.getReserveNormalizedIncome.selector),
            abi.encode(1)
        );

        vm.expectRevert("Aave: module not profitable");
        _harvest(address(goblinBank), OWNER);
    }
}
