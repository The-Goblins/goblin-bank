// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./deployer/TimelockDeployer.s.sol";
import "./deployer/GoblinBankDeployer.s.sol";
import "./deployer/StargateDeployer.s.sol";
import "./deployer/AaveDeployer.s.sol";
import "./deployer/CompoundV3Deployer.s.sol";
import "./deployer/UniV3Deployer.s.sol";
import "./deployer/FeeManagerDeployer.s.sol";

contract Deployer is CompoundV3Deployer, UniV3Deployer, TimelockDeployer, GoblinBankDeployer, StargateDeployer, AaveDeployer, FeeManagerDeployer {

    function run() external virtual {
        // Load data needed for the deployment
        // BASE_TOKEN_NAME, TIMELOCK, OWNER, and MANAGER must be set in .env
        loadData();
        //setDex();
        //setTimelock();

        // Set to true to deploy a new dex or a new timelock
        // If set to true, it overrides the fetched and set dex and timelock above
        bool doDex = true;
        bool doTimelock = true;

        // deploy and setup the contracts
        vm.startBroadcast();
        deployAll(doDex, doTimelock, PRIVATE_DEPLOYMENT_ROLE_ACCOUNTS);
        addAllModules();
        setModuleAllocation();
        goblinBank.unpause();
        transferAllOwnership(doDex);
        renounceAllRoles(DEPLOYER);
        vm.stopBroadcast();

        // check that the contract have been correctly deployed and initialized
        verifyAll(doDex);

        // print the addresses of the components
        printComponentAddresses();

        // print the storage of the components
        printComponentStorage();
    }

    // used only by ProposalChecker when we have addresses fetched from on-chain data
    function setAll() internal {
        setTimelock();
        setUniV3Dex();
        setGoblinBankImpl();
        setGoblinBank();
        if (STARGATE_ACTIVE) {
            setStargateYieldModuleImpl();
            setStargateYieldModule();
        }
        if (AAVE_ACTIVE) {
            setAaveYieldModuleImpl();
            setAaveYieldModule();
        }
        if (COMPOUND_V3_ACTIVE) {
            setCompoundV3YieldModuleImpl();
            setCompoundV3YieldModule();
        }
    }

    function deployAll(bool doDex, bool doTimelock, address[] memory privateAccessAccounts) internal {
        // When we have a dex in prod we maybe don't want to deploy it again.
        // However we have to add the new routes manually through the multisig.
        if (doTimelock) {
            deployTimelock();
        }
        if (doDex) {
            deployUniV3();
        }

        deployFeeManager(TEAM_SHARE, TREASURY_SHARE, STAKING_SHARE);

        deployGoblinBankImpl();
        deployGoblinBank(address(timelock), privateAccessAccounts, address(feeManager));

        if (STARGATE_ACTIVE) {
            deployStargateYieldModuleImpl();
            deployStargateYieldModule(address(goblinBank), address(uniV3));
        }
        if (AAVE_ACTIVE) {
            deployAaveYieldModuleImpl();
            deployAaveYieldModule(address(goblinBank), address(uniV3));
        }
        if (COMPOUND_V3_ACTIVE) {
            deployCompoundV3YieldModuleImpl();
            deployCompoundV3YieldModule(address(goblinBank), address(uniV3));
        }
    }

    function addAllModules() internal {
        if (STARGATE_ACTIVE) {
            addStargateToGoblinBank(stargateYieldModule);
        }
        if (AAVE_ACTIVE) {
            addAaveToGoblinBank(aaveYieldModule);
        }
        if (COMPOUND_V3_ACTIVE) {
            addCompoundV3ToGoblinBank(compoundV3YieldModule);
        }
    }

    function transferAllOwnership(bool doDex) internal {
        transferOwnershipFeeManager(address(timelock));
        if (doDex) {
            transferOwnershipUniV3Dex(address(timelock));
        }
        if (STARGATE_ACTIVE) {
            transferOwnershipStargateYieldModule(address(timelock));
        }
        if (AAVE_ACTIVE) {
            transferOwnershipAaveYieldModule(address(timelock));
        }
        if (COMPOUND_V3_ACTIVE) {
            transferOwnershipCompoundV3YieldModule(address(timelock));
        }
    }

    function verifyAll(bool doDex) internal {
        verifyTimelock();
        if (doDex) {
            verifyUniV3Dex(address(timelock));
        }
        verifyFeeManager(address(timelock));
        verifyGoblinBank(address(timelock), address(feeManager));
        if (STARGATE_ACTIVE) {
            verifyStargateYieldModule(address(timelock), address(goblinBank), address(uniV3));
        }
        if (AAVE_ACTIVE) {
            verifyAaveYieldModule(address(timelock), address(goblinBank), address(uniV3));
        }
        if (COMPOUND_V3_ACTIVE) {
            verifyCompoundV3YieldModule(address(timelock), address(goblinBank), address(uniV3));
        }
    }

    function printComponentAddresses() internal view {
        console2.log(
            "------------------------------------------------------------------------------------------------"
        );
        console2.log("Deployer address:                     ", DEPLOYER);
        console2.log("Owner (Multisig) address:             ", OWNER);
        console2.log("Manager (Multisig) address:           ", MANAGER);
        console2.log("Timelock address:                     ", address(timelock));
        console2.log("uniV3 address:                          ", address(uniV3));
        console2.log(
            "Goblin Bank impl address:          ",
            address(goblinBankImpl)
        );
        console2.log(
            "Goblin Bank address:               ",
            address(goblinBank)
        );
        console2.log(
            "Stargate yield module impl address:   ",
            address(stargateYieldModuleImpl)
        );
        console2.log(
            "Stargate yield module address:        ",
            address(stargateYieldModule)
        );
        console2.log(
            "Aave yield module impl address:       ",
            address(aaveYieldModuleImpl)
        );
        console2.log(
            "Aave yield module address:            ",
            address(aaveYieldModule)
        );
        console2.log(
            "Compound V3 yield module address:     ",
            address(compoundV3YieldModule)
        );
        console2.log(
            "------------------------------------------------------------------------------------------------"
        );
    }

    function printComponentStorage() internal view {
        if (address(uniV3) != address(0)) {
            printUniV3DexStorage();
        }
        if (address(goblinBank) != address(0)) {
            printGoblinBankStorage();
        }
        if (address(stargateYieldModule) != address(0)) {
            printStargateStorage();
        }
        if (address(aaveYieldModule) != address(0)) {
            printAaveStorage();
        }
        if (address(compoundV3YieldModule) != address(0)) {
            printCompoundV3Storage();
        }
    }
}
