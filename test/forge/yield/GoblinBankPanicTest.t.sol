// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../script/Deployer.s.sol";
import "./GoblinBankBasicTestHelper.t.sol";

contract GoblinBankModulesTest is GoblinBankBasicTestHelper {
    using SafeERC20 for IERC20;

    function testPanicEmptiesModules() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);

        for (uint256 i = 0; i < goblinBank.numberOfModules(); i++) {
            (IYieldModule module, uint allocation) = goblinBank.yieldOptions(i);
            assertApproxEqAbs(module.getBalance(), DEPOSIT_AMOUNT * allocation / goblinBank.MAX_BPS(), PRECISION);
        }

        _moveBlock(1000);
        goblinBank.harvest();

        _moveBlock(1);

        vm.prank(address(timelock));
        goblinBank.panic();

        for (uint256 i = 0; i < goblinBank.numberOfModules(); i++) {
            (IYieldModule module,) = goblinBank.yieldOptions(i);
            assertApproxEqAbs(module.getBalance(), 0, goblinBank.numberOfModules() * PRECISION);
        }
    }

    function testPanicShouldSendFundsToManager() public {
        testPanicEmptiesModules();

        //Gt because harvest is counted
        assertGt(IERC20(goblinBank.baseToken()).balanceOf(address(goblinBank)), DEPOSIT_AMOUNT);
    }

    function testBalanceSnapshotShouldBeEqualToLocalBalanceAfterPanic() public {
        testPanicEmptiesModules();

        assertEq(IERC20(goblinBank.baseToken()).balanceOf(address(goblinBank)), goblinBank.balanceSnapshot());
    }

    function testRandomAddressCanNotPanic() public {
        vm.prank(RANDOM_ADDRESS);
        //with RANDOM_ADDRESS == 0x305ad87a471f49520218feaf4146e26d9f068eb4 and PANICOOOR_ROLE == 0xa342a293161a8d2ea19a8f810f41e62de0d97b54d0eddb3a7b5e2abcc379c931
        vm.expectRevert(bytes('AccessControl: account 0x305ad87a471f49520218feaf4146e26d9f068eb4 is missing role 0xa342a293161a8d2ea19a8f810f41e62de0d97b54d0eddb3a7b5e2abcc379c931'));
        goblinBank.panic();
    }

    function testOwnerCanPanic() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);
        vm.prank(address(timelock));
        goblinBank.panic();
    }

    function testManagerCanPanic() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);
        vm.prank(MANAGER);
        goblinBank.panic();
    }

    function testPanicShouldPause() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);

        vm.prank(address(timelock));
        goblinBank.panic();

        assertEq(goblinBank.paused(), true);
    }

    function testFinishPanicShouldUnpause() public {
        testPanicShouldPause();

        vm.prank(address(timelock));
        goblinBank.finishPanic();

        assertEq(goblinBank.paused(), false);
    }

    function testFinishPanicShouldResetBalanceSnapshot() public {
        testPanicShouldPause();

        vm.prank(address(timelock));
        goblinBank.finishPanic();

        assertEq(goblinBank.balanceSnapshot(), 0);
    }

    function testManagerCanFinishPanicNotRandomAddress() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);

        vm.prank(MANAGER);
        goblinBank.panic();

        vm.prank(RANDOM_ADDRESS);
        //with RANDOM_ADDRESS == 0x305ad87a471f49520218feaf4146e26d9f068eb4
        vm.expectRevert(bytes('AccessControl: account 0x305ad87a471f49520218feaf4146e26d9f068eb4 is missing role 0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08'));
        goblinBank.finishPanic();

        vm.prank(MANAGER);
        goblinBank.finishPanic();
    }

    function testOwnerCanFinishPanicNotRandomAddress() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);

        vm.prank(address(timelock));
        goblinBank.panic();

        vm.prank(RANDOM_ADDRESS);
        //with RANDOM_ADDRESS == 0x305ad87a471f49520218feaf4146e26d9f068eb4
        vm.expectRevert(bytes('AccessControl: account 0x305ad87a471f49520218feaf4146e26d9f068eb4 is missing role 0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08'));
        goblinBank.finishPanic();

        vm.prank(address(timelock));
        goblinBank.finishPanic();
    }

    function testCanOnlyFinishPanicIfAllFundsAreBackInTheGoblinBank() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);

        vm.prank(address(timelock));
        goblinBank.panic();

        uint256 goblinBankBalance = IERC20(BASE_TOKEN).balanceOf(address(goblinBank));
        deal(BASE_TOKEN, address(goblinBank), goblinBankBalance / 2);

        vm.prank(address(timelock));
        vm.expectRevert(bytes("GoblinBank: funds still pending"));
        goblinBank.finishPanic();

        deal(BASE_TOKEN, address(goblinBank), goblinBankBalance);

        vm.prank(address(timelock));
        goblinBank.finishPanic();
    }

    function testFinishPanicAcceptASmallDifferenceBetweenTheLocalBalanceAndTheBalanceSnapshot() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);

        vm.prank(address(timelock));
        goblinBank.panic();

        uint256 goblinBankBalance = IERC20(BASE_TOKEN).balanceOf(address(goblinBank));
        deal(BASE_TOKEN, address(goblinBank), goblinBankBalance * (MAX_BPS - 10) / MAX_BPS - 1);

        vm.prank(address(timelock));
        vm.expectRevert(bytes("GoblinBank: funds still pending"));
        goblinBank.finishPanic();

        deal(BASE_TOKEN, address(goblinBank), goblinBankBalance * (MAX_BPS - 10) / MAX_BPS);

        vm.prank(address(timelock));
        goblinBank.finishPanic();
        assertEq(goblinBank.paused(), false);
    }

    function testShouldDepositOnFinishPanic() public {
        testPanicEmptiesModules();

        vm.prank(address(timelock));
        goblinBank.finishPanic();

        for (uint256 i = 0; i < goblinBank.numberOfModules(); i++) {
            (IYieldModule module, uint allocation) = goblinBank.yieldOptions(i);
            assertGt(module.getBalance(), DEPOSIT_AMOUNT * allocation / goblinBank.MAX_BPS());
        }
        assertEq(IERC20(goblinBank.baseToken()).balanceOf(address(goblinBank)), 0);
    }

    function testShouldDepositEntireBaseTokenBalance() public {
        testShouldDepositOnFinishPanic();

        //deposit extra baseToken on GoblinBank
        deal(goblinBank.baseToken(), address(goblinBank), DEPOSIT_AMOUNT);

        _moveBlock(10);

        vm.prank(address(timelock));
        goblinBank.panic();
        assertGt(IERC20(goblinBank.baseToken()).balanceOf(address(goblinBank)), DEPOSIT_AMOUNT * 2);

        vm.prank(address(timelock));
        goblinBank.finishPanic();

        for (uint256 i = 0; i < goblinBank.numberOfModules(); i++) {
            (IYieldModule module, uint allocation) = goblinBank.yieldOptions(i);
            assertGt(module.getBalance(), DEPOSIT_AMOUNT * allocation / goblinBank.MAX_BPS());
        }
        assertEq(IERC20(goblinBank.baseToken()).balanceOf(address(goblinBank)), 0);
    }

    function testPanicShouldSetPricePerShareToZero() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);

        vm.prank(address(timelock));
        goblinBank.panic();

        uint ppsAfter = goblinBank.pricePerShare();
        assertEq(ppsAfter, 0);
    }

    function testPanicFinishPanicShouldNotChangePricePerShare() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);

        uint ppsBefore = goblinBank.pricePerShare();

        vm.startPrank(address(timelock));
        goblinBank.panic();
        _moveBlock(1);
        goblinBank.finishPanic();

        uint ppsAfter = goblinBank.pricePerShare();
        assertApproxEqAbs(ppsBefore, ppsAfter, IOU_DECIMALS / PRECISION);
    }

    function testPanicWithMultipleModules() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);
        depositHelper(BOB, DEPOSIT_AMOUNT);

        _moveBlock(10000);

        vm.prank(address(timelock));
        goblinBank.panic();
        assertGt(IERC20(goblinBank.baseToken()).balanceOf(address(goblinBank)), DEPOSIT_AMOUNT * 2);
        for (uint256 i = 0; i < goblinBank.numberOfModules(); i++) {
            (IYieldModule module,) = goblinBank.yieldOptions(i);
            // In aave there only reward APY so the balance does not increase
            assertEq(module.getBalance(), 0);
        }
    }

    function testShouldHaveMaxBPSAllocation() public {
        testPanicShouldPause();

        vm.startPrank(address(timelock));

        //remove a module with an allocation != 0
        (, uint allocation) = goblinBank.yieldOptions(0);
        assertGt(allocation, 0);
        goblinBank.removeModule(0);

        vm.expectRevert(bytes("GoblinBank: total allocation is wrong"));
        goblinBank.finishPanic();
        vm.stopPrank();
    }

    function testModuleShouldNotHaveAllocationSetToZero() public {
        testPanicShouldPause();

        vm.startPrank(address(timelock));

        (IYieldModule module, uint allocation) = goblinBank.yieldOptions(0);
        goblinBank.addModule(module);

        vm.expectRevert(bytes("GoblinBank: Min allocation too low"));
        goblinBank.finishPanic();

        uint numberOfModules = goblinBank.numberOfModules();
        uint[] memory allocations = new uint[](numberOfModules);
        for (uint256 i = 0; i < goblinBank.numberOfModules(); i++) {
            (IYieldModule module,) = goblinBank.yieldOptions(i);
            // In aave there only reward APY so the balance does not increase
            allocations[i] = goblinBank.MAX_BPS() / numberOfModules;
        }

        if (numberOfModules == 3)
            allocations[numberOfModules - 1]++;

        goblinBank.setModuleAllocation(allocations);
        goblinBank.finishPanic();

        assertEq(goblinBank.paused(), false);
        vm.stopPrank();
    }
}
