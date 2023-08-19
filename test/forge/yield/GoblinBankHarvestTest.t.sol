// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../script/Deployer.s.sol";
import "./GoblinBankBasicTestHelper.t.sol";

contract GoblinBankHarvestTest is GoblinBankBasicTestHelper {
    using SafeERC20 for IERC20;

    function testHarvestGrowsTheIouValue() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);

        uint256 lastUpdatedPricePerShareBefore = goblinBank.lastUpdatedPricePerShare();
        uint256 pricePerShareBefore = goblinBank.pricePerShare();
        _moveBlock(1000);

        assertGt(
            goblinBank.lastUpdatedPricePerShare(),
            lastUpdatedPricePerShareBefore
        );

        goblinBank.harvest();

        uint256 lastUpdatedPricePerShareAfter = goblinBank.lastUpdatedPricePerShare();
        uint256 pricePerShareAfter = goblinBank.pricePerShare();
        assertGt(pricePerShareAfter, pricePerShareBefore);
        assertGt(lastUpdatedPricePerShareAfter, lastUpdatedPricePerShareBefore);
    }

    function testShouldHarvest0IfSupplyIsNull() public {
        uint256 totalSupply = goblinBank.totalSupply();
        assertEq(totalSupply, 0);

        uint256 profit = goblinBank.harvest();
        assertEq(profit, 0);
    }

    function testShouldSendPerfFeeToFeeManager() public {
        vm.prank(address(timelock));
        goblinBank.setPerformanceFee(10 * 100);

        testHarvestGrowsTheIouValue();

        assertGt(IERC20(BASE_TOKEN).balanceOf(goblinBank.feeManager()), 0);
    }

    function testShouldReturnNetProfitOnly() public {
        vm.prank(address(timelock));
        goblinBank.setPerformanceFee(0);
        depositHelper(ALICE, DEPOSIT_AMOUNT);
        _moveBlock(10000000);
        //0% perf fee
        goblinBank.harvest();
        assertEq(IERC20(BASE_TOKEN).balanceOf(address(feeManager)), 0);
        withdrawHelper(ALICE, goblinBank.balanceOf(ALICE));
        assertEq(goblinBank.getModulesBalance(), 0);
        assertGt(IERC20(BASE_TOKEN).balanceOf(ALICE), DEPOSIT_AMOUNT);

        vm.prank(address(timelock));
        uint16 perfFee = MAX_BPS / 10;
        //10% perf fee
        goblinBank.setPerformanceFee(perfFee);

        depositHelper(ALICE, DEPOSIT_AMOUNT);
        _moveBlock(10000000);
        uint256 netProfit = goblinBank.harvest();
        uint profit = (MAX_BPS * netProfit) / (MAX_BPS - perfFee);
        uint perfProfit = perfFee * profit / MAX_BPS;

        assertApproxEqAbs(IERC20(BASE_TOKEN).balanceOf(address(feeManager)), 0, PRECISION);
        assertApproxEqAbs(
            IERC20(BASE_TOKEN).balanceOf(TEAM_ADDRESS),
            (perfProfit * TEAM_SHARE) / MAX_BPS,
            goblinBank.numberOfModules() * PRECISION
        );

        assertApproxEqAbs(
            IERC20(BASE_TOKEN).balanceOf(TREASURY_ADDRESS),
            (perfProfit * TREASURY_SHARE) / MAX_BPS,
            goblinBank.numberOfModules() * PRECISION
        );

        assertApproxEqAbs(
            IERC20(BASE_TOKEN).balanceOf(STAKING_ADDRESS),
            (perfProfit * STAKING_SHARE) / MAX_BPS,
            goblinBank.numberOfModules() * PRECISION
        );
    }

    function testShouldCompoundProfits() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);
        _moveBlock(10000000);
        uint256 netProfit = goblinBank.harvest();
        //90%
        assertApproxEqAbs(goblinBank.getModulesBalance(), DEPOSIT_AMOUNT + netProfit, 5*PRECISION);
    }
}
