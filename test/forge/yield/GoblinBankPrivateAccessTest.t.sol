// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GoblinBankBasicTestHelper.t.sol";


contract GoblinBankPrivateAccessTest is GoblinBankBasicTestHelper {
    using SafeERC20 for IERC20;


    address[] privateAccessAccounts = [makeAddr("PRIVATE1"), makeAddr("PRIVATE2"), makeAddr("PRIVATE3")];

    bytes32 PRIVATE_ACCESS_ROLE;

    function setUp() public override {
        super.setUp();
        PRIVATE_ACCESS_ROLE = goblinBank.PRIVATE_ACCESS_ROLE();
    }

    function setPrivateAccessAccounts() internal override view returns(address[] memory) {
        return privateAccessAccounts;
    }

    function testDepositForPrivateAccounts() public {
        for(uint256 i = 0; i < privateAccessAccounts.length; i++) {
            depositHelper(privateAccessAccounts[i], DEPOSIT_AMOUNT);
            assertEq(IERC20(BASE_TOKEN).balanceOf(privateAccessAccounts[i]), 0);
            assertApproxEqAbs(goblinBank.balanceOf(privateAccessAccounts[i]), DEPOSIT_AMOUNT, PRECISION);
        }
    }

    function testWithdrawForPrivateAccounts() public {
        for(uint256 i = 0; i < privateAccessAccounts.length; i++) {
            depositHelper(privateAccessAccounts[i], DEPOSIT_AMOUNT);
            assertEq(IERC20(BASE_TOKEN).balanceOf(privateAccessAccounts[i]), 0);
            assertApproxEqAbs(goblinBank.balanceOf(privateAccessAccounts[i]), DEPOSIT_AMOUNT, PRECISION);
        }

        for(uint256 i = 0; i < privateAccessAccounts.length; i++) {
            uint shares = goblinBank.balanceOf(privateAccessAccounts[i]);
            vm.prank(privateAccessAccounts[i]);
            goblinBank.withdraw(shares);
            uint sharesAfter = goblinBank.balanceOf(privateAccessAccounts[i]);
            assertEq(sharesAfter, 0);
        }
    }

    function testShouldFailIfDepositFormUnauthorizedAccount() public {
        address token = goblinBank.baseToken();
        vm.startPrank(address(ALICE));

        deal(token, ALICE, DEPOSIT_AMOUNT);
        if (IERC20(token).allowance(ALICE, address(goblinBank)) == 0) {
            IERC20(token).safeApprove(address(goblinBank), type(uint256).max);
        }
        vm.expectRevert("AccessControl: account 0xef211076b8d8b46797e09c9a374fb4cdc1df0916 is missing role 0x0c68cdb6fd6b65e5d48d3b80ffc99a3d28ac2ee7bc6ebb6d554797ee6f192643");
        goblinBank.deposit(DEPOSIT_AMOUNT);
        vm.stopPrank();
    }

    function testShouldFailIfWithdrawFormUnauthorizedAccount() public {
        vm.startPrank(address(ALICE));
        vm.expectRevert("AccessControl: account 0xef211076b8d8b46797e09c9a374fb4cdc1df0916 is missing role 0x0c68cdb6fd6b65e5d48d3b80ffc99a3d28ac2ee7bc6ebb6d554797ee6f192643");
        goblinBank.withdraw(666); // random number, there is nothing in the vault
        vm.stopPrank();
    }

    function testCheckingIfAccountHasPrivateAccess() public {
        for(uint256 i = 0; i < privateAccessAccounts.length; i++) {
            assertEq(goblinBank.hasRole(PRIVATE_ACCESS_ROLE, privateAccessAccounts[i]), true);
        }
        assertEq(goblinBank.hasRole(PRIVATE_ACCESS_ROLE, RANDOM_ADDRESS), false);
    }

    function testAddingAccountToPrivateAccess() public {
        // only manager can add
        vm.prank(MANAGER);
        goblinBank.grantRole(PRIVATE_ACCESS_ROLE, ALICE);

        assertEq(goblinBank.getRoleMemberCount(PRIVATE_ACCESS_ROLE), 4);
        assertEq(goblinBank.getRoleMember(PRIVATE_ACCESS_ROLE, 3), ALICE);

        // no other account can add account
        vm.startPrank(BOB);
        vm.expectRevert("AccessControl: account 0xa53b369bdcbe05dcbb96d6550c924741902d2615 is missing role 0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08");
        goblinBank.grantRole(PRIVATE_ACCESS_ROLE, RANDOM_ADDRESS);
        vm.stopPrank();
    }

    function testRemovingAccountFromPrivateAccess() public {
        // only manager can add
        vm.prank(MANAGER);
        goblinBank.revokeRole(PRIVATE_ACCESS_ROLE, privateAccessAccounts[0]);

        assertEq(goblinBank.getRoleMemberCount(PRIVATE_ACCESS_ROLE), 2);
        assertEq(goblinBank.getRoleMember(PRIVATE_ACCESS_ROLE, 0), privateAccessAccounts[2]);
        assertEq(goblinBank.getRoleMember(PRIVATE_ACCESS_ROLE, 1), privateAccessAccounts[1]);
        assertEq(isAddressInArray(privateAccessAccounts[1], goblinBank.roleAccounts(PRIVATE_ACCESS_ROLE)), true);
        assertEq(isAddressInArray(privateAccessAccounts[2], goblinBank.roleAccounts(PRIVATE_ACCESS_ROLE)), true);
        assertEq(goblinBank.hasRole(PRIVATE_ACCESS_ROLE, privateAccessAccounts[1]), true);
        assertEq(goblinBank.hasRole(PRIVATE_ACCESS_ROLE, privateAccessAccounts[2]), true);
        assertEq(goblinBank.hasRole(PRIVATE_ACCESS_ROLE, privateAccessAccounts[0]), false);

        // no other account can add account
        vm.startPrank(BOB);
        vm.expectRevert("AccessControl: account 0xa53b369bdcbe05dcbb96d6550c924741902d2615 is missing role 0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08");
        goblinBank.revokeRole(PRIVATE_ACCESS_ROLE, privateAccessAccounts[1]);
        vm.stopPrank();
    }

    function testIfRoleAccountListIsCorrect() public {
        address test1 = makeAddr("TEST1");
        address test2 = makeAddr("TEST2");

        vm.startPrank(MANAGER);

        assertEq(goblinBank.getRoleMemberCount(PRIVATE_ACCESS_ROLE), 3);
        assertEq(goblinBank.roleAccounts(PRIVATE_ACCESS_ROLE).length, 3);

        goblinBank.grantRole(PRIVATE_ACCESS_ROLE, test1);
        goblinBank.grantRole(PRIVATE_ACCESS_ROLE, test2);

        assertEq(goblinBank.getRoleMemberCount(PRIVATE_ACCESS_ROLE), 5);
        assertEq(goblinBank.roleAccounts(PRIVATE_ACCESS_ROLE).length, 5);
        assertEq(isAddressInArray(test1, goblinBank.roleAccounts(PRIVATE_ACCESS_ROLE)), true);
        assertEq(isAddressInArray(test2, goblinBank.roleAccounts(PRIVATE_ACCESS_ROLE)), true);
        assertEq(goblinBank.hasRole(PRIVATE_ACCESS_ROLE, test1), true);
        assertEq(goblinBank.hasRole(PRIVATE_ACCESS_ROLE, test2), true);

        goblinBank.revokeRole(PRIVATE_ACCESS_ROLE, test1);
        goblinBank.revokeRole(PRIVATE_ACCESS_ROLE, test2);

        assertEq(goblinBank.getRoleMemberCount(PRIVATE_ACCESS_ROLE), 3);
        assertEq(goblinBank.roleAccounts(PRIVATE_ACCESS_ROLE).length, 3);
        assertEq(isAddressInArray(test1, goblinBank.roleAccounts(PRIVATE_ACCESS_ROLE)), false);
        assertEq(isAddressInArray(test2, goblinBank.roleAccounts(PRIVATE_ACCESS_ROLE)), false);
        assertEq(goblinBank.hasRole(PRIVATE_ACCESS_ROLE, test1), false);
        assertEq(goblinBank.hasRole(PRIVATE_ACCESS_ROLE, test2), false);

        vm.stopPrank();
    }

    function testPrivateAccessRoleCannotCallOnlyManager() public {
        vm.startPrank(MANAGER);
        goblinBank.grantRole(goblinBank.PRIVATE_ACCESS_ROLE(), RANDOM_ADDRESS);
        vm.stopPrank();

        assertEq(goblinBank.hasRole(goblinBank.PRIVATE_ACCESS_ROLE(), RANDOM_ADDRESS), true);

        vm.startPrank(RANDOM_ADDRESS);
        //with RANDOM_ADDRESS == 0x305ad87a471f49520218feaf4146e26d9f068eb4 and MANAGER_ROLE = 0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08
        vm.expectRevert('AccessControl: account 0x305ad87a471f49520218feaf4146e26d9f068eb4 is missing role 0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08');
        goblinBank.finishPanic();
        vm.stopPrank();
    }

    function isAddressInArray(address account, address[] memory array) internal view returns(bool) {
        for(uint i = 0; i < array.length; i++) {
            if(array[i] == account) {
                return true;
            }
        }
        return false;
    }

}
