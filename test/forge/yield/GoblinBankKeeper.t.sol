 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0;

 import "./GoblinBankBasicTestHelper.t.sol";

 contract GoblinBankKeeper is GoblinBankBasicTestHelper {

    bytes public HARVEST_PROFIT_BYTES = bytes("HARVEST_PROFIT");

     function testCheckUpkeepHarvestProfit() public {
        (bool upkeepNeeded, bytes memory performData) = goblinBank.checkUpkeep(HARVEST_PROFIT_BYTES);
        assertTrue(upkeepNeeded);
        assertEq(keccak256(performData), keccak256(HARVEST_PROFIT_BYTES));
    }

    function testCheckUpkeepUnknownTaskReturnFalseAndEmptyPerformData() public {
        (bool upkeepNeeded, bytes memory performData) = goblinBank.checkUpkeep(bytes("RANDOM_TASK"));
        assertTrue(!upkeepNeeded);
        assertEq(keccak256(performData), keccak256(""));
    }

    function testPerformUpkeepHarvestProfit() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);

        _moveBlock(100000000);

        uint256 ppsBefore = goblinBank.pricePerShare();
        goblinBank.performUpkeep(HARVEST_PROFIT_BYTES);
        uint256 ppsAfter = goblinBank.pricePerShare();
        assertGt(ppsAfter, ppsBefore);
    }

    function testPerformUpkeepHarvestProfitFailWhenProfitAreLowerThanHarvestThreshold() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);

        vm.expectRevert("GoblinBank: not enough to harvest");
        goblinBank.performUpkeep(HARVEST_PROFIT_BYTES);
    }

    function testPerformUpkeepUnknownTaskRevert() public {
        vm.expectRevert(bytes("Unknown task"));
        goblinBank.performUpkeep(bytes("RANDOM_TASK"));
    }
 }
