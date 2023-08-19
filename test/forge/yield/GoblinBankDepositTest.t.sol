 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0;

 import "./GoblinBankBasicTestHelper.t.sol";

 contract GoblinBankDepositTest is GoblinBankBasicTestHelper {
     using SafeERC20 for IERC20;

     function testDeposit() public {
         depositHelper(ALICE, DEPOSIT_AMOUNT);
         assertEq(IERC20(BASE_TOKEN).balanceOf(ALICE), 0);
         assertEq(goblinBank.balanceOf(ALICE), DEPOSIT_AMOUNT);
     }

     function testShouldNotDepositLessThanMinAmount() public {
         vm.startPrank(ALICE);
         IERC20(goblinBank.baseToken()).safeApprove(address(goblinBank), type(uint256).max);
         vm.expectRevert(bytes("GoblinBank: amount too small"));
         goblinBank.deposit(0);
         vm.stopPrank();
     }

     function testShouldEmitEvent() public {
         vm.startPrank(ALICE);
         deal(BASE_TOKEN, ALICE, DEPOSIT_AMOUNT);
         IERC20(goblinBank.baseToken()).safeApprove(address(goblinBank), type(uint256).max);

         vm.expectEmit(false, false, false, true, address(goblinBank));
         emit Deposit(ALICE, DEPOSIT_AMOUNT);
         goblinBank.deposit(DEPOSIT_AMOUNT);

         vm.stopPrank();
     }

     function testShouldHaveShares() public {
         depositHelper(ALICE, DEPOSIT_AMOUNT);
         assertEq(goblinBank.balanceOf(ALICE), DEPOSIT_AMOUNT);
     }

     function testShouldHaveEqualSharesAtStart() public {
         depositHelper(ALICE, DEPOSIT_AMOUNT);
         depositHelper(BOB, DEPOSIT_AMOUNT);

         assertApproxEqAbs(goblinBank.balanceOf(ALICE), goblinBank.balanceOf(BOB), goblinBank.numberOfModules() * PRECISION);
     }

     function testShouldHaveFundsAccordingToAllocation() public {
         depositHelper(ALICE, DEPOSIT_AMOUNT);

         for (uint i = 0; i < goblinBank.numberOfModules(); i++) {
             (IYieldModule module, uint allocation) = goblinBank.yieldOptions(i);
             uint fundsInThisModule = DEPOSIT_AMOUNT * allocation / goblinBank.MAX_BPS();
             assertApproxEqAbs(fundsInThisModule, module.getBalance(), goblinBank.numberOfModules() * PRECISION);
         }
     }

     function testShouldHarvestOnDepositWhenTotalSupply() public {
         depositHelper(ALICE, DEPOSIT_AMOUNT);

         vm.startPrank(BOB);
         deal(BASE_TOKEN, BOB, DEPOSIT_AMOUNT);
         IERC20(goblinBank.baseToken()).safeApprove(address(goblinBank), type(uint256).max);

         vm.expectEmit(false, false, false, false);
         emit Harvest(0);
         goblinBank.deposit(DEPOSIT_AMOUNT);

         vm.stopPrank();
     }

     function testCannotDepositWhenPaused() public {
         vm.prank(address(timelock));
         goblinBank.pause();

         vm.startPrank(BOB);
         deal(BASE_TOKEN, BOB, DEPOSIT_AMOUNT);
         IERC20(goblinBank.baseToken()).safeApprove(address(goblinBank), type(uint256).max);
         vm.expectRevert(bytes("Pausable: paused"));
         goblinBank.deposit(DEPOSIT_AMOUNT);

         vm.stopPrank();
     }

     function testCanDepositAfterUnpause() public {
         testCannotDepositWhenPaused();

         vm.prank(address(timelock));
         goblinBank.unpause();

         vm.prank(BOB);
         goblinBank.deposit(DEPOSIT_AMOUNT);

         assertEq(goblinBank.balanceOf(BOB), DEPOSIT_AMOUNT);
     }
 }
