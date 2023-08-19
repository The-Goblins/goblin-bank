// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DataLoader.s.sol";
import "../AddressFetcher.s.sol";
import "../../contracts/yield/interface/IGoblinBank.sol";
import "../../contracts/yield/interface/IYieldModule.sol";
import "../../contracts/yield/GoblinBank.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract GoblinBankDeployer is DataLoader, AddressFetcher {
    GoblinBank public goblinBankImpl;
    GoblinBank public goblinBank;
    uint256[] moduleAllocations;

    function setGoblinBankImpl() internal {
        goblinBankImpl = GoblinBank(payable(goblinBankImplAddress));
    }

    function setGoblinBank() internal {
        goblinBank = GoblinBank(payable(goblinBankAddress));
    }

    function deployGoblinBankImpl() internal {
        goblinBankImpl = new GoblinBank();
    }

    function deployGoblinBank(address timelock, address[] memory privateAccessAccounts, address feeManager) internal {
        ERC1967Proxy proxy = new ERC1967Proxy(address(goblinBankImpl), "");
        goblinBank = GoblinBank(payable(proxy));
        goblinBank.initialize(
            SM_NAME,
            SM_SYMBOL,
            feeManager,
            BASE_TOKEN,
            SM_MIN_HARVEST_THRESHOLD_IN_BASE_TOKEN,
            SM_PERFORMANCE_FEE,
            SM_CAP,
            MANAGER,
            timelock,
            SM_MIN_AMOUNT,
            privateAccessAccounts
        );
        goblinBank.pause();
    }

    function verifyGoblinBank(address timelock, address feeManager) internal {
        assertEq(
            address(goblinBank) != 0x0000000000000000000000000000000000000000,
            true
        );
        assertEq(goblinBank.getImplementation(), address(goblinBankImpl));

        //ADMIN role granted to owner == timelock + can StopActivity
        assertEq(goblinBank.hasRole(goblinBank.DEFAULT_ADMIN_ROLE(), timelock), true);
        assertEq(goblinBank.hasRole(goblinBank.MANAGER_ROLE(), timelock), true);

        //MANAGER ROLE granted to Manager + can StopActivity
        assertEq(goblinBank.hasRole(goblinBank.MANAGER_ROLE(), MANAGER), true);

        //No roles for deployer
        assertEq(goblinBank.hasRole(goblinBank.MANAGER_ROLE(), DEPLOYER), false);
        assertEq(goblinBank.hasRole(goblinBank.DEFAULT_ADMIN_ROLE(), DEPLOYER), false);

        assertEq(goblinBank.name(), SM_NAME);
        assertEq(goblinBank.symbol(), SM_SYMBOL);
        assertEq(goblinBank.feeManager(), feeManager, "goblinBank.feeManager() != feeManager");
        assertEq(goblinBank.baseToken(), BASE_TOKEN);
        assertEq(
            goblinBank.minHarvestThreshold(),
            SM_MIN_HARVEST_THRESHOLD_IN_BASE_TOKEN
        );
        assertEq(goblinBank.performanceFee(), SM_PERFORMANCE_FEE);
        assertEq(goblinBank.cap(), SM_CAP);
        assertEq(goblinBank.minAmount(), SM_MIN_AMOUNT);

        //If private deployment then private accounts must be declared
        if(goblinBank.isPrivateAccess()) {
            assertGt(goblinBank.getRoleMemberCount(goblinBank.PRIVATE_ACCESS_ROLE()), 0);
        } else {
            assertEq(goblinBank.getRoleMemberCount(goblinBank.PRIVATE_ACCESS_ROLE()), 0);
        }

        assertEq(goblinBank.hasRole(goblinBank.DEFAULT_ADMIN_ROLE(), timelock), true, "timelock missing DEFAULT_ADMIN_ROLE");
        assertEq(goblinBank.hasRole(goblinBank.MANAGER_ROLE(), timelock), true, "timelock missing MANAGER_ROLE");
        assertEq(goblinBank.hasRole(goblinBank.MANAGER_ROLE(), MANAGER), true, "manager missing MANAGER_ROLE");

        // TODO: verify allocation
    }

    function printGoblinBankStorage() internal view {
        console.log("\nGoblin Bank storage");
        console.log("Implementation:     ", goblinBank.getImplementation());
        console.log("Name:               ", goblinBank.name());
        console.log("Symbol:             ", goblinBank.symbol());
        console.log("Fee manager:        ", goblinBank.feeManager());
        console.log("baseToken:          ", goblinBank.baseToken());
        console.log("Min harvest thld :  ", goblinBank.minHarvestThreshold());
        console.log("Performance fee:    ", goblinBank.performanceFee());
        console.log("Cap:                ", goblinBank.cap());
        console.log("Min amount:         ", goblinBank.minAmount());
    }

    /* add modules */

    function addStargateToGoblinBank(IYieldModule stargateModule) internal {
        goblinBank.addModule(stargateModule);
    }

    function addAaveToGoblinBank(IYieldModule aaveModule) internal {
        goblinBank.addModule(aaveModule);
    }

    function addCompoundV3ToGoblinBank(IYieldModule compoundV3YieldModule) internal {
        goblinBank.addModule(compoundV3YieldModule);
    }

    /* add allocation */

    function setModuleAllocation() internal {
        if (STARGATE_ACTIVE) {
            moduleAllocations.push(STARGATE_ALLOCATION);
        }
        if (AAVE_ACTIVE) {
            moduleAllocations.push(AAVE_ALLOCATION);
        }
        if (COMPOUND_V3_ACTIVE) {
            moduleAllocations.push(COMPOUND_V3_ALLOCATION);
        }
        goblinBank.setModuleAllocation(moduleAllocations);
    }

    /* renounce role */

    function renounceAllRoles(address user) internal {
        renounceAdminRole(user);
        renounceManagerRole(user);
        renounceManagerRole(user);
    }

    function renounceAdminRole(address isAdmin) internal {
        goblinBank.renounceRole(goblinBank.DEFAULT_ADMIN_ROLE(), isAdmin);
    }

    function renounceManagerRole(address isManager) internal {
        goblinBank.renounceRole(goblinBank.MANAGER_ROLE(), isManager);
    }

    function revokeManagerRole(address isManager) internal {
        goblinBank.revokeRole(goblinBank.MANAGER_ROLE(), isManager);
    }

    function revokePanicooorRole(address isPanicooor) internal {
        goblinBank.revokeRole(goblinBank.PANICOOOR_ROLE(), isPanicooor);
    }
}
