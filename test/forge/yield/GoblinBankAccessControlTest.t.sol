// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GoblinBankBasicTestHelper.t.sol";

contract GoblinBankAccessControlTest is GoblinBankBasicTestHelper {
    using SafeERC20 for IERC20;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    function testOwnerHasAllRoles() public {
        assertEq(goblinBank.hasRole(DEFAULT_ADMIN_ROLE, address(timelock)), true);
        assertEq(goblinBank.hasRole(goblinBank.MANAGER_ROLE(), address(timelock)), true);
        assertEq(goblinBank.hasRole(goblinBank.PANICOOOR_ROLE(), address(timelock)), true);
    }

    function testDeployerHasNoRole() public {
        assertEq(goblinBank.hasRole(DEFAULT_ADMIN_ROLE, DEPLOYER), false);
        assertEq(goblinBank.hasRole(goblinBank.MANAGER_ROLE(), DEPLOYER), false);
        assertEq(goblinBank.hasRole(goblinBank.PANICOOOR_ROLE(), DEPLOYER), false);
        assertEq(goblinBank.hasRole(0x00, DEPLOYER), false);

    }

    function testRandomHasNoRole() public {
        assertEq(goblinBank.hasRole(DEFAULT_ADMIN_ROLE, RANDOM_ADDRESS), false);
        assertEq(goblinBank.hasRole(goblinBank.MANAGER_ROLE(), RANDOM_ADDRESS), false);
        assertEq(goblinBank.hasRole(goblinBank.PANICOOOR_ROLE(), RANDOM_ADDRESS), false);
    }

    function testAddressZeroIsNotDefaultAdmin() public {
        assertEq(goblinBank.hasRole(0x00, address(0)), false);
    }

    function testDefaultAdminIsTheAdminRole() public {
        assertEq(goblinBank.getRoleAdmin(DEFAULT_ADMIN_ROLE), DEFAULT_ADMIN_ROLE);
        assertEq(goblinBank.getRoleAdmin(goblinBank.PANICOOOR_ROLE()), DEFAULT_ADMIN_ROLE);
        assertEq(goblinBank.getRoleAdmin(goblinBank.MANAGER_ROLE()), DEFAULT_ADMIN_ROLE);

    }

    function testAdminRoleCanGrantRolesToRandom() public {
        vm.startPrank(address(timelock));
        goblinBank.grantRole(DEFAULT_ADMIN_ROLE, RANDOM_ADDRESS);
        goblinBank.grantRole(goblinBank.MANAGER_ROLE(), RANDOM_ADDRESS);
        goblinBank.grantRole(goblinBank.PANICOOOR_ROLE(), RANDOM_ADDRESS);
        vm.stopPrank();

        assertEq(goblinBank.hasRole(DEFAULT_ADMIN_ROLE, RANDOM_ADDRESS), true);
        assertEq(goblinBank.hasRole(goblinBank.MANAGER_ROLE(), RANDOM_ADDRESS), true);
        assertEq(goblinBank.hasRole(goblinBank.PANICOOOR_ROLE(), RANDOM_ADDRESS), true);
    }

    function testAdminRoleCanRevokeRolesToRandom() public {
        testAdminRoleCanGrantRolesToRandom();

        vm.startPrank(address(timelock));
        goblinBank.revokeRole(DEFAULT_ADMIN_ROLE, RANDOM_ADDRESS);
        goblinBank.revokeRole(goblinBank.MANAGER_ROLE(), RANDOM_ADDRESS);
        goblinBank.revokeRole(goblinBank.PANICOOOR_ROLE(), RANDOM_ADDRESS);
        vm.stopPrank();

        assertEq(goblinBank.hasRole(DEFAULT_ADMIN_ROLE, RANDOM_ADDRESS), false);
        assertEq(goblinBank.hasRole(goblinBank.MANAGER_ROLE(), RANDOM_ADDRESS), false);
        assertEq(goblinBank.hasRole(goblinBank.PANICOOOR_ROLE(), RANDOM_ADDRESS), false);
    }

    function testManagerRoleCannotRevokeAdminRole() public {
        vm.startPrank(address(timelock));
        goblinBank.grantRole(goblinBank.MANAGER_ROLE(), RANDOM_ADDRESS);
        vm.stopPrank();

        assertEq(goblinBank.hasRole(goblinBank.MANAGER_ROLE(), RANDOM_ADDRESS), true);

        vm.startPrank(RANDOM_ADDRESS);
        //with RANDOM_ADDRESS == 0x305ad87a471f49520218feaf4146e26d9f068eb4 and DEFAULT_ADMIN_ROLE = 0x00
        vm.expectRevert('AccessControl: account 0x305ad87a471f49520218feaf4146e26d9f068eb4 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000');
        goblinBank.revokeRole(DEFAULT_ADMIN_ROLE, address(timelock));
        vm.stopPrank();
    }

    function testManagerRoleCannotRevokeManagerRole() public {
        vm.startPrank(address(timelock));
        goblinBank.grantRole(goblinBank.MANAGER_ROLE(), BOB);
        goblinBank.grantRole(goblinBank.MANAGER_ROLE(), ALICE);
        vm.stopPrank();

        vm.startPrank(BOB);
        bytes32 role = goblinBank.MANAGER_ROLE();
        //with BOB == 0xa53b369bdcbe05dcbb96d6550c924741902d2615 and DEFAULT_ADMIN_ROLE = 0x00
        vm.expectRevert('AccessControl: account 0xa53b369bdcbe05dcbb96d6550c924741902d2615 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000');
        goblinBank.revokeRole(role, ALICE);
        vm.stopPrank();
    }

    function testManagerRoleCannotRevokePanicooorRole() public {
        vm.startPrank(address(timelock));
        goblinBank.grantRole(goblinBank.PANICOOOR_ROLE(), RANDOM_ADDRESS);
        vm.stopPrank();

        vm.startPrank(RANDOM_ADDRESS);
        bytes32 role = goblinBank.PANICOOOR_ROLE();
        //with RANDOM_ADDRESS == 0x305ad87a471f49520218feaf4146e26d9f068eb4 and DEFAULT_ADMIN_ROLE = 0x00
        vm.expectRevert('AccessControl: account 0x305ad87a471f49520218feaf4146e26d9f068eb4 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000');
        goblinBank.revokeRole(role, address(timelock));
        vm.stopPrank();
    }

    function testPanicooorRoleCannotRevokeAdminRole() public {
        vm.startPrank(address(timelock));
        goblinBank.grantRole(goblinBank.PANICOOOR_ROLE(), RANDOM_ADDRESS);
        vm.stopPrank();

        vm.startPrank(RANDOM_ADDRESS);
        //with RANDOM_ADDRESS == 0x305ad87a471f49520218feaf4146e26d9f068eb4 and DEFAULT_ADMIN_ROLE = 0x00
        vm.expectRevert('AccessControl: account 0x305ad87a471f49520218feaf4146e26d9f068eb4 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000');
        goblinBank.revokeRole(DEFAULT_ADMIN_ROLE, address(timelock));
        vm.stopPrank();
    }

    function testManagerRoleCannotCallOnlyAdmin() public {
        vm.startPrank(address(timelock));
        goblinBank.grantRole(goblinBank.MANAGER_ROLE(), RANDOM_ADDRESS);
        vm.stopPrank();

        assertEq(goblinBank.hasRole(goblinBank.MANAGER_ROLE(), RANDOM_ADDRESS), true);

        vm.startPrank(RANDOM_ADDRESS);
        //with RANDOM_ADDRESS == 0x305ad87a471f49520218feaf4146e26d9f068eb4 and DEFAULT_ADMIN_ROLE = 0x00
        vm.expectRevert('AccessControl: account 0x305ad87a471f49520218feaf4146e26d9f068eb4 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000');
        goblinBank.setFeeManager(BOB);
        vm.stopPrank();
    }

    function testPanicooorRoleCannotCallOnlyAdmin() public {
        vm.startPrank(address(timelock));
        goblinBank.grantRole(goblinBank.PANICOOOR_ROLE(), RANDOM_ADDRESS);
        vm.stopPrank();

        assertEq(goblinBank.hasRole(goblinBank.PANICOOOR_ROLE(), RANDOM_ADDRESS), true);

        vm.startPrank(RANDOM_ADDRESS);
        //with RANDOM_ADDRESS == 0x305ad87a471f49520218feaf4146e26d9f068eb4 and DEFAULT_ADMIN_ROLE = 0x00
        vm.expectRevert('AccessControl: account 0x305ad87a471f49520218feaf4146e26d9f068eb4 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000');
        goblinBank.setFeeManager(BOB);
        vm.stopPrank();
    }

    function testPanicooorRoleCannotCallOnlyManager() public {
        vm.startPrank(address(timelock));
        goblinBank.grantRole(goblinBank.PANICOOOR_ROLE(), RANDOM_ADDRESS);
        vm.stopPrank();

        assertEq(goblinBank.hasRole(goblinBank.PANICOOOR_ROLE(), RANDOM_ADDRESS), true);

        vm.startPrank(RANDOM_ADDRESS);
        //with RANDOM_ADDRESS == 0x305ad87a471f49520218feaf4146e26d9f068eb4 and MANAGER_ROLE = 0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08
        vm.expectRevert('AccessControl: account 0x305ad87a471f49520218feaf4146e26d9f068eb4 is missing role 0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08');
        goblinBank.finishPanic();
        vm.stopPrank();
    }

    function testMakeSureTheresNoOpenRole() public {
        vm.startPrank(address(timelock));
        goblinBank.grantRole(keccak256("RANDOM_OPEN_ROLE"), RANDOM_ADDRESS);
        vm.stopPrank();

        vm.startPrank(RANDOM_ADDRESS);
        //with RANDOM_ADDRESS == 0x305ad87a471f49520218feaf4146e26d9f068eb4 and PANICOOOR_ROLE = 0xa342a293161a8d2ea19a8f810f41e62de0d97b54d0eddb3a7b5e2abcc379c931
        vm.expectRevert('AccessControl: account 0x305ad87a471f49520218feaf4146e26d9f068eb4 is missing role 0xa342a293161a8d2ea19a8f810f41e62de0d97b54d0eddb3a7b5e2abcc379c931');
        goblinBank.panic();

        //with RANDOM_ADDRESS == 0x305ad87a471f49520218feaf4146e26d9f068eb4 and MANAGER_ROLE = 0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08
        vm.expectRevert('AccessControl: account 0x305ad87a471f49520218feaf4146e26d9f068eb4 is missing role 0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08');
        goblinBank.setMinHarvestThreshold(10);
        vm.stopPrank();
    }

    function testPanicooorRoleCanPanic() public {
        depositHelper(ALICE, DEPOSIT_AMOUNT);
        _moveBlock(1000);

        vm.startPrank(MANAGER);
        assertEq(goblinBank.hasRole(goblinBank.PANICOOOR_ROLE(), MANAGER), true);
        goblinBank.panic();
        vm.stopPrank();

        assertApproxEqAbs(goblinBank.getModulesBalance(), 0, goblinBank.numberOfModules() * PRECISION);
        assertGe(IERC20(goblinBank.baseToken()).balanceOf(address(goblinBank)), DEPOSIT_AMOUNT);
    }

    function testPublicDeploymentCanNotAddPrivateAccessAccounts() public {
        bytes32 privateAccessRole = goblinBank.PRIVATE_ACCESS_ROLE();

        vm.startPrank(address(timelock));
        vm.expectRevert('PRIVATE_ACCESS_ROLE not allowed in public deployment');
        goblinBank.grantRole(privateAccessRole, BOB);
        vm.stopPrank();

        vm.startPrank(MANAGER);
        // MANAGER in public deployment does not have admin rights over PRIVATE_ACCESS_ROLE
        vm.expectRevert("AccessControl: account 0x194c0dac11062ce04c52e9fd09e604784f4dcc49 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000");
        goblinBank.grantRole(privateAccessRole, ALICE);
        vm.stopPrank();
    }
}
