// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GoblinBankBasicTestHelper.t.sol";

contract GoblinBankGettersTest is GoblinBankBasicTestHelper {
    using SafeERC20 for IERC20;

    function testModuleBalanceImpreciseAtDeposit() public {
        assertEq(goblinBank.getLastUpdatedModulesBalance(), 0);
        assertEq(goblinBank.getModulesBalance(), 0);
        depositHelper(ALICE, DEPOSIT_AMOUNT);
        assertApproxEqAbs(goblinBank.getLastUpdatedModulesBalance(), DEPOSIT_AMOUNT, PRECISION);
        assertApproxEqAbs(goblinBank.getModulesBalance(), DEPOSIT_AMOUNT, PRECISION);
        _moveBlock(1000);
        assertLe(goblinBank.getLastUpdatedModulesBalance(), goblinBank.getModulesBalance());
        assertGt(goblinBank.getModulesBalance(), DEPOSIT_AMOUNT);
        assertGt(goblinBank.getLastUpdatedModulesBalance(), DEPOSIT_AMOUNT);
    }

    function testGetExecutionFee() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);

        uint256 executionFeeSmallAmount = goblinBank.getExecutionFee(1e18);
        uint256 expectedExecutionFeeSmallAmount = 0;
        for (uint256 i = 0; i < goblinBank.numberOfModules(); i++) {
            (IYieldModule module,) = goblinBank.yieldOptions(i);
            expectedExecutionFeeSmallAmount += module.getExecutionFee(1e18);
        }
        assertEq(executionFeeSmallAmount, expectedExecutionFeeSmallAmount);
        assertEq(executionFeeSmallAmount, 0);

        if (address(stargateYieldModule) != address(0)) {
            vm.mockCall(
                address(stargateYieldModule),
                abi.encodeWithSelector(StargateYieldModule.getExecutionFee.selector),
                abi.encode(300000000000000000) // 0.03 AVAX
            );

            uint256 executionFeeBigAmount = goblinBank.getExecutionFee(1e18);
            uint256 expectedExecutionFeeBigAmount = 0;
            for (uint256 i = 0; i < goblinBank.numberOfModules(); i++) {
                (IYieldModule module,) = goblinBank.yieldOptions(i);
                expectedExecutionFeeBigAmount += module.getExecutionFee(1e18);
            }
            assertEq(executionFeeBigAmount, expectedExecutionFeeBigAmount);
            assertGt(executionFeeBigAmount, 0);
        }
    }
}
