// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CompoundV3BaseTest.t.sol";

contract CompoundV3WithdrawTest is CompoundV3BaseTest {

    uint256 COMPOUND_IOU_APPROX = 1;

    function testCanWithdraw() public {
        uint256 shareFraction = SMALL_AMOUNT * 1e18 / BIG_AMOUNT;

        _deposit(address(goblinBank), BIG_AMOUNT);
        _withdraw(address(goblinBank), shareFraction, ALICE);

        assertApproxEqAbs(yieldModule.getBalance(), BIG_AMOUNT - SMALL_AMOUNT, PRECISION);
        assertEq(IERC20(yieldModule.baseToken()).balanceOf(address(yieldModule)), 0);
        assertEq(IERC20(yieldModule.baseToken()).balanceOf(address(goblinBank)), 0);
        assertApproxEqAbs(IERC20(yieldModule.baseToken()).balanceOf(ALICE), SMALL_AMOUNT, PRECISION);
    }

    function testCanWithdrawAll() public {
        _deposit(address(goblinBank), SMALL_AMOUNT);
        _withdraw(address(goblinBank), ALL_SHARE_AS_FRACTION, ALICE);

        assertEq(yieldModule.getBalance(), 0);
        assertEq(IERC20(yieldModule.baseToken()).balanceOf(address(yieldModule)), 0);
        assertEq(IERC20(yieldModule.baseToken()).balanceOf(address(goblinBank)), 0);
        assertApproxEqAbs(IERC20(yieldModule.baseToken()).balanceOf(ALICE), SMALL_AMOUNT, PRECISION);
    }

    function testOnlyGoblinBankCanWithdraw() public {
        _deposit(address(goblinBank), SMALL_AMOUNT);
        _withdraw(address(goblinBank), ALL_SHARE_AS_FRACTION, ALICE);

        vm.prank(RANDOM_ADDRESS);
        vm.expectRevert("BaseModule: only vault");
        yieldModule.withdraw(ALL_SHARE_AS_FRACTION, ALICE);
    }

    function testOwnerCannotWithdraw() public {
        vm.prank(OWNER);
        vm.expectRevert("BaseModule: only vault");
        yieldModule.withdraw(ALL_SHARE_AS_FRACTION, ALICE);
    }

    function testManagerCannotWithdraw() public {
        vm.prank(MANAGER);
        vm.expectRevert("BaseModule: only vault");
        yieldModule.withdraw(ALL_SHARE_AS_FRACTION, ALICE);
    }

    function testWithdrawShareFractionCannotBeZero() public {
        vm.prank(address(goblinBank));
        vm.expectRevert("CompoundV3: amount cannot be zero");
        yieldModule.withdraw(0, ALICE);
    }

    function testMsgValueMustBeZeroToWithdraw() public {
        deal(address(goblinBank), 1e17);
        vm.prank(address(goblinBank));
        vm.expectRevert("CompoundV3: msg.value must be zero");
        yieldModule.withdraw{value : 1e17}(ALL_SHARE_AS_FRACTION, ALICE);
    }

    function testWithdrawEmitEvent() public {
        _deposit(address(goblinBank), SMALL_AMOUNT);
        console.log("SMALL_AMOUNT : ", SMALL_AMOUNT);

        vm.startPrank(address(goblinBank));
        vm.expectEmit(false, false, false, false);
        emit Withdraw(yieldModule.baseToken(), SMALL_AMOUNT);
        yieldModule.withdraw(ALL_SHARE_AS_FRACTION, ALICE);
        vm.stopPrank();
    }

    function testShouldFailOnLpTokenRescueWithdrawal() public {
        address lpToken = yieldModule.cometToken();
        vm.startPrank(OWNER);
        vm.expectRevert(bytes("BaseModule: can't pull out lp tokens"));
        yieldModule.rescueToken(lpToken);
        vm.stopPrank();
    }

    function testShouldAllowTokenRescueWithdrawal() public {
        deal(yieldModule.baseToken(), address(yieldModule), SMALL_AMOUNT);
        _moveBlock(1);
        assertEq(IERC20(yieldModule.baseToken()).balanceOf(OWNER), 0);
        vm.startPrank(OWNER);
        yieldModule.rescueToken(yieldModule.baseToken());
        assertEq(IERC20(yieldModule.baseToken()).balanceOf(OWNER), SMALL_AMOUNT);
        vm.stopPrank();
    }
}
