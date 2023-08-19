// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Deployer.s.sol";

contract Updatoor is Deployer {

    function run() external override {
        // Load data and set components needed for the deployment
        // BASE_TOKEN_NAME, TIMELOCK, OWNER, and MANAGER must be set in .env
        loadData();
        setUniV3Dex();
        setTimelock();

        // Fetch and set components that have been already deployed
        // [TOKEN]_SMART_FARMOOOR, DEX AND TIMELOCK must be set in .env
        fetchAddresses(GOBLIN_BANK_ADDRESS);

        // explicitly set the values for active modules, by default they are set to current on chain values of GoblinBank fetched using fetchAddresses()
        STARGATE_ACTIVE = STARGATE_ACTIVE_CURRENT_VALUE;
        AAVE_ACTIVE = AAVE_ACTIVE_CURRENT_VALUE;

        setGoblinBank();

        // deploy and set up contracts
        vm.startBroadcast();

        // ... deployment and after deployment function calls

        vm.stopBroadcast();

        // check that the contract have been correctly deployed and initialized
        verifyGoblinBank(address(timelock), address(feeManager));

        // print the addresses of the components
        printComponentAddresses();
    }
}
