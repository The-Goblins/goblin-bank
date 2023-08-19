// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StargateBaseTest.t.sol";
import "../../../../../contracts/yield/interface/stargate/IPool.sol";

contract StargateHarvestTest is StargateBaseTest {

    function testCanHarvest() public {
        _deposit(address(goblinBank), SMALL_AMOUNT);
        _moveBlock(1000);
        _harvest(address(goblinBank), SMALL_AMOUNT, address(goblinBank));

        assertApproxEqAbs(stargateYieldModule.getBalance(), SMALL_AMOUNT, 1);
        assertEq(IERC20(stargateYieldModule.baseToken()).balanceOf(address(stargateYieldModule)), 0);
        assertGt(IERC20(stargateYieldModule.baseToken()).balanceOf(address(goblinBank)), 0);
    }

    function testOnlyGoblinBankCanHarvest() public {
        _deposit(address(goblinBank), SMALL_AMOUNT);
        _moveBlock(1000);
        _harvest(address(goblinBank), SMALL_AMOUNT, address(goblinBank));
        _moveBlock(1000);

        vm.prank(RANDOM_ADDRESS);
        vm.expectRevert("BaseModule: only vault");
        stargateYieldModule.harvest(address(goblinBank));
    }

    function testOwnerCannotHarvest() public {
        vm.prank(OWNER);
        vm.expectRevert("BaseModule: only vault");
        stargateYieldModule.harvest(address(goblinBank));
    }

    function testManagerCannotHarvest() public {
        vm.prank(MANAGER);
        vm.expectRevert("BaseModule: only vault");
        stargateYieldModule.harvest(address(goblinBank));
    }

    function testHarvestEmitEvent() public {
        _deposit(address(goblinBank), SMALL_AMOUNT);
        _moveBlock(1000);

        vm.startPrank(address(goblinBank));
        vm.expectEmit(false, false, false, false);
        emit Harvest(stargateYieldModule.baseToken(), 0);
        stargateYieldModule.harvest(address(goblinBank));
        vm.stopPrank();
    }


    function testHarvestRevertOnLpTokenValueDecrease() public {
        _deposit(address(goblinBank), SMALL_AMOUNT);
        _moveBlock(1000);

         // decrease LP token liquidity in Stargate pool - it will decrease LP token value
         vm.mockCall(
            stargateYieldModule.pool(),
            abi.encodeWithSelector(IPool.totalLiquidity.selector),
            abi.encode(uint256(1000))
        );

        vm.startPrank(address(goblinBank));
        vm.expectRevert("Stargate: currentPricePerShare smaller than last one");
        stargateYieldModule.harvest(address(goblinBank));
        vm.stopPrank();
    }
}
