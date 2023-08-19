// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GoblinBankBasicTestHelper.t.sol";

contract GoblinBankModulesTest is GoblinBankBasicTestHelper {
    using SafeERC20 for IERC20;

    function testShouldAddModulesWhenPaused() public {
        (IYieldModule newModule,) = goblinBank.yieldOptions(0);
        vm.startPrank(address(timelock));
        vm.expectRevert(bytes("Pausable: not paused"));
        goblinBank.addModule(newModule);

        uint initialNumberOfModule = goblinBank.numberOfModules();

        goblinBank.pause();
        goblinBank.addModule(newModule);

        assertEq(goblinBank.numberOfModules(), initialNumberOfModule + 1);
        vm.stopPrank();
    }

    function testShouldSetModuleAllocation() public {
        uint[] memory allocations = new uint[](goblinBank.numberOfModules());
        for (uint256 i = 0; i < goblinBank.numberOfModules(); i++) {
            (, uint allocation) = goblinBank.yieldOptions(i);
            allocations[i] = allocation;
        }

        allocations[0] = allocations[0] - 100;
        allocations[1] = allocations[1] + 100;
        vm.startPrank(address(timelock));
        goblinBank.pause();
        goblinBank.setModuleAllocation(allocations);
        goblinBank.unpause();
        vm.stopPrank();

        (, uint allocationModule1) = goblinBank.yieldOptions(0);
        (, uint allocationModule2) = goblinBank.yieldOptions(1);

        assertEq(allocationModule1, allocations[0]);
        assertEq(allocationModule2, allocations[1]);
    }
    /*
         function testShouldOnlySetCorrectAllocationSize() public {
                //add extra module
                testShouldAddModulesWhenEmptyModules();
                uint[] memory allocations = new uint[](smartFarmooor.numberOfModules() - 1);

                //array too small
                vm.prank(address(timelock));
                vm.expectRevert(bytes("GoblinBank: Allocation list size issue"));
                smartFarmooor.setModuleAllocation(allocations);

                //array too big
                allocations = new uint[](smartFarmooor.numberOfModules() + 1);
                vm.prank(address(timelock));
                vm.expectRevert(bytes("GoblinBank: Allocation list size issue"));
                smartFarmooor.setModuleAllocation(allocations);

                //correct size
                uint numberOfModules = smartFarmooor.numberOfModules();
                allocations = new uint[](numberOfModules);
                for (uint256 i = 0; i < numberOfModules; i++) {
                    allocations[i] = smartFarmooor.MAX_BPS() / numberOfModules;
                }

                if (smartFarmooor.MAX_BPS() - ((smartFarmooor.MAX_BPS() / numberOfModules) * numberOfModules) != 0) {
                    allocations[numberOfModules - 1] += smartFarmooor.MAX_BPS() - ((smartFarmooor.MAX_BPS() / numberOfModules) * numberOfModules);
                }

                vm.prank(address(timelock));
                smartFarmooor.setModuleAllocation(allocations);

                for (uint256 i = 0; i < smartFarmooor.numberOfModules(); i++) {
                    (, uint allocation) = smartFarmooor.yieldOptions(i);
                    assertEq(allocation, allocations[i]);
                }
            } */

    function testShouldDepositAccordingToAllocation() public {
        testShouldSetModuleAllocation();
        vm.prank(address(timelock));

        depositHelper(ALICE, DEPOSIT_AMOUNT);

        for (uint256 i = 0; i < goblinBank.numberOfModules(); i++) {
            (IYieldModule module, uint allocation) = goblinBank.yieldOptions(i);
            assertApproxEqAbs(module.getBalance(), DEPOSIT_AMOUNT * allocation / goblinBank.MAX_BPS(), goblinBank.numberOfModules() * PRECISION);
        }
    }

    function testShouldRemoveModuleThatExists() public {
        uint initialNumberOfModule = goblinBank.numberOfModules();

        vm.startPrank(address(timelock));
        goblinBank.pause();

        vm.expectRevert(bytes("GoblinBank : module does not exist"));
        goblinBank.removeModule(initialNumberOfModule);

        goblinBank.removeModule(initialNumberOfModule - 1);
        assertEq(goblinBank.numberOfModules(), initialNumberOfModule - 1);
        vm.stopPrank();
    }

    function testOnlyManagerShouldRemove() public {
        uint initialNumberOfModule = goblinBank.numberOfModules();

        vm.prank(ALICE);
        //with ALICE == 0xef211076b8d8b46797e09c9a374fb4cdc1df0916 and MAANGER ROLE = 0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08
        vm.expectRevert(bytes('AccessControl: account 0xef211076b8d8b46797e09c9a374fb4cdc1df0916 is missing role 0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08'));
        goblinBank.removeModule(0);

        assertEq(goblinBank.hasRole(goblinBank.MANAGER_ROLE(), address(timelock)), true);
        vm.startPrank(address(timelock));
        goblinBank.pause();

        goblinBank.removeModule(initialNumberOfModule - 1);
        assertEq(goblinBank.numberOfModules(), initialNumberOfModule - 1);
        vm.stopPrank();
    }

    function testShouldRemoveOnlyWhenPaused() public {
        uint initialNumberOfModule = goblinBank.numberOfModules();

        vm.startPrank(address(timelock));
        vm.expectRevert(bytes("Pausable: not paused"));
        goblinBank.removeModule(0);

        goblinBank.pause();

        goblinBank.removeModule(0);
        assertEq(goblinBank.numberOfModules(), initialNumberOfModule - 1);
        (IYieldModule first,) = goblinBank.yieldOptions(initialNumberOfModule - 1);
        assertEq(address(first), address(0));
        vm.stopPrank();
    }

    function testShouldRemoveOnlyWhenEmpty() public {
        uint initialNumberOfModule = goblinBank.numberOfModules();

        depositHelper(ALICE, DEPOSIT_AMOUNT);

        vm.startPrank(address(timelock));
        goblinBank.pause();
        vm.expectRevert(bytes("GoblinBank: module not empty"));
        goblinBank.removeModule(0);

        goblinBank.unpause();
        goblinBank.panic();
        goblinBank.removeModule(0);

        assertEq(goblinBank.numberOfModules(), initialNumberOfModule - 1);
    }

    function testShouldDeleteOldDataWhenRemoved() public {
        vm.startPrank(address(timelock));
        goblinBank.pause();

        // Remove all module
        uint initialNumberOfModule = goblinBank.numberOfModules();
        for (uint256 i = 0; i < initialNumberOfModule; i++) {
            goblinBank.removeModule(initialNumberOfModule - 1 - i);
        }
        assertEq(goblinBank.numberOfModules(), 0);

        for (uint256 i = 0; i < initialNumberOfModule; i++) {
            (IYieldModule module, uint allocation) = goblinBank.yieldOptions(i);
            assertEq(address(module), address(0));
            assertEq(allocation, 0);
        }

        vm.stopPrank();
    }

    function testShouldRemoveMiddleModule() public {
        vm.startPrank(address(timelock));
        goblinBank.pause();

        // Remove all module expect one
        uint initialNumberOfModule = goblinBank.numberOfModules();
        for (uint256 i = 0; i < initialNumberOfModule - 1; i++) {
            goblinBank.removeModule(initialNumberOfModule - 1 - i);
        }

        //add benqi again : 1 benqi, 2 benqi
        goblinBank.addModule(_deployExtraCompoundV3Module(BASE_TOKEN));
        CompoundV3Module thirdCompV3Module = _deployExtraCompoundV3Module(BASE_TOKEN);
        goblinBank.addModule(thirdCompV3Module);

        uint[] memory allocations = new uint[](goblinBank.numberOfModules());

        allocations[0] = uint(goblinBank.MAX_BPS() / 2);
        allocations[1] = uint(goblinBank.MAX_BPS() / 4);
        allocations[2] = uint(goblinBank.MAX_BPS() / 4);

        goblinBank.setModuleAllocation(allocations);

        goblinBank.unpause();
        vm.stopPrank();

        depositHelper(ALICE, DEPOSIT_AMOUNT);

        vm.startPrank(address(timelock));
        _moveBlock(10000);
        goblinBank.harvest();

        assertEq(goblinBank.numberOfModules(), 3);

        _moveBlock(1);

        goblinBank.panic();
        goblinBank.removeModule(1);

        (IYieldModule second,) = goblinBank.yieldOptions(1);
        (IYieldModule third,) = goblinBank.yieldOptions(2);

        //third is no second since we removed middle module
        assertEq(address(second), address(thirdCompV3Module));
        assertEq(address(third), address(0));

        allocations = new uint[](goblinBank.numberOfModules());
        allocations[0] = uint(goblinBank.MAX_BPS() / 2);
        allocations[1] = uint(goblinBank.MAX_BPS() / 2);

        goblinBank.setModuleAllocation(allocations);
        goblinBank.finishPanic();

        vm.stopPrank();

        assertEq(goblinBank.numberOfModules(), 2);
    }

    /* function testTotalAllocationShouldAlwaysBeMaxBps() public {
        testShouldAddModulesWhenEmptyModules();

        vm.startPrank(address(timelock));
        uint numberOfModules = smartFarmooor.numberOfModules();

        uint[] memory allocations = new uint[](numberOfModules);
        for (uint256 i = 0; i < numberOfModules; i++) {
            allocations[i] = smartFarmooor.MAX_BPS() * 2 / numberOfModules;
        }

        vm.expectRevert(bytes("GoblinBank: total allocation is wrong"));
        smartFarmooor.setModuleAllocation(allocations);

        numberOfModules = smartFarmooor.numberOfModules();
        allocations = new uint[](numberOfModules);
        for (uint256 i = 0; i < numberOfModules; i++) {
            allocations[i] = smartFarmooor.MAX_BPS() / numberOfModules;
        }

        allocations[numberOfModules - 1] += _fillLastModuleWithRestOfAllocation(numberOfModules);
        console.log(" allocations[numberOfModules - 1] : ", allocations[numberOfModules - 1]);

        smartFarmooor.setModuleAllocation(allocations);

        for (uint256 i = 0; i < numberOfModules - 1; i++) {
            (, uint allocation) = smartFarmooor.yieldOptions(i);
            assertEq(allocation, smartFarmooor.MAX_BPS() / numberOfModules);
        }

        vm.stopPrank();
    } */

    function testModuleMinAllocationShouldBe10Percent() public {
        //add comp v3 again : 1 comp V3, 2 comp V3
        assertEq(goblinBank.hasRole(goblinBank.MANAGER_ROLE(), address(timelock)), true);
        vm.startPrank(address(timelock));
        goblinBank.pause();

        uint numberOfModules = goblinBank.numberOfModules();
        uint[] memory allocations = new uint[](numberOfModules);
        uint256 i = 0;
        for (i; i < numberOfModules; i++) {
            (, uint allocation) = goblinBank.yieldOptions(i);
            allocations[i] = 80;
        }

        vm.expectRevert("GoblinBank: Min allocation too low");
        goblinBank.setModuleAllocation(allocations);


        //get down to 2 modules active
        i = numberOfModules - 1;
        if (numberOfModules > 2) {
            while (goblinBank.numberOfModules() != 2) {
                goblinBank.removeModule(i);
                i--;
            }
        }

        allocations = new uint[](goblinBank.numberOfModules());
        allocations[0] = 100;
        allocations[1] = goblinBank.MAX_BPS() - allocations[0];


        goblinBank.setModuleAllocation(allocations);

        (, uint allocationModule1) = goblinBank.yieldOptions(0);
        (, uint allocationModule2) = goblinBank.yieldOptions(1);


        assertEq(allocationModule1, 100);
        assertEq(allocationModule2, goblinBank.MAX_BPS() - allocations[0]);

        vm.stopPrank();
    }

    function testAddModuleRevertIfBaseTokenDoesNotMatch() public {
        IYieldModule wrongModule = _deployExtraCompoundV3Module(ARB);
        vm.startPrank(address(timelock));
        goblinBank.pause();
        vm.expectRevert(bytes("GoblinBank: not compatible module"));
        goblinBank.addModule(wrongModule);
        vm.stopPrank();
    }

    function _deployExtraCompoundV3Module(address want) internal returns (CompoundV3Module) {
        address[] memory rewards = new address[](1);
        rewards[0] = COMP;

        CompoundV3Module compoundV3YieldModuleImpl = new CompoundV3Module();
        ERC1967Proxy proxy = new ERC1967Proxy(address(compoundV3YieldModuleImpl), "");
        CompoundV3Module compoundV3YieldModule = CompoundV3Module(payable(proxy));
        compoundV3YieldModule.initialize(address(goblinBank), MANAGER, want, COMPOUND_V3_EXECUTION_FEE, address(uniV3),
            rewards, COMPOUND_V3_USDC, COMPOUND_V3_REWARDOR, COMPOUND_V3_YIELD_MODULE_NAME, WRAPPED_NATIVE_TOKEN);

        return compoundV3YieldModule;
    }
}
