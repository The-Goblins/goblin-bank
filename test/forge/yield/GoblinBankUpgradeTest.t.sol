// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GoblinBankBasicTestHelper.t.sol";
import "../mock/GoblinBankUpgradedMock.sol";
import "../mock/UniswapV3UpgradedMock.sol";

contract GoblinBankUpgradeTest is GoblinBankBasicTestHelper {

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    function testSetShouldUpgrade() public {
        uint dummyVersion = 1;
        GoblinBankUpgradedMock upgradedGoblinBank = new GoblinBankUpgradedMock();

        assertTrue(goblinBank.hasRole(DEFAULT_ADMIN_ROLE, address(timelock)));
        vm.prank(address(timelock));
        goblinBank.upgradeTo(address(upgradedGoblinBank));
        GoblinBankUpgradedMock(payable(goblinBank)).initializev2(dummyVersion);

        //set the implem at mock address
        goblinBankImpl = upgradedGoblinBank;
        assertEq(GoblinBankUpgradedMock(payable(goblinBank)).dummyVersion(), dummyVersion);
        verifyGoblinBank(address(timelock), address(feeManager));
    }

    function testRandomCannotUpgrade() public {
        uint dummyVersion = 1;
        GoblinBankUpgradedMock upgradedGoblinBank = new GoblinBankUpgradedMock();

        assertTrue(!goblinBank.hasRole(DEFAULT_ADMIN_ROLE, RANDOM_ADDRESS));
        vm.prank(RANDOM_ADDRESS);
        vm.expectRevert("AccessControl: account 0x305ad87a471f49520218feaf4146e26d9f068eb4 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000");
        goblinBank.upgradeTo(address(upgradedGoblinBank));
    }

    function testShouldUpgradeUniswap() public {
        uint dummyVersion = 43;
        UniswapV3UpgradedMock upgradedUniSwap = new UniswapV3UpgradedMock();

        assertEq(uniV3.owner(), address(timelock));
        vm.prank(address(timelock));
        uniV3.upgradeTo(address(upgradedUniSwap));
        UniswapV3UpgradedMock(address(uniV3)).initializev2(dummyVersion);

        //set the implem at mock address
        uniV3Impl = upgradedUniSwap;
        assertEq(UniswapV3UpgradedMock(address(uniV3)).dummyVersion(), dummyVersion);
        verifyFeeManager(address(timelock));
    }
}
