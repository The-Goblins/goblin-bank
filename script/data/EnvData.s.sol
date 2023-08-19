pragma solidity ^0.8.0;

import "forge-std/Script.sol";

/**
This script file reads environment variables if they exist. When run locally, the
.env file is sourced before the execution of any script so they are always present.
On the other hand, the github action does not source the .env before running
the tests because it does not have access to it. In that case the address zero is
set here and then overridden by the DataLoader.
 */

contract EnvData is Script {
    string BASE_TOKEN_NAME = vm.envOr("BASE_TOKEN_NAME", string(""));
    address TIMELOCK = vm.envOr("TIMELOCK_ADDRESS", address(0));
    address OWNER = vm.envOr("OWNER_ADDRESS", address(0));
    address MANAGER = vm.envOr("MANAGER_ADDRESS", address(0));
    address DEPLOYER = vm.envOr("DEPLOYER_ADDRESS", address(0));
    address TEAM_ADDRESS = vm.envOr("TEAM_ADDRESS", address(0));
    address TREASURY_ADDRESS = vm.envOr("TREASURY_ADDRESS", address(0));
    address STAKING_ADDRESS = vm.envOr("STAKING_ADDRESS", address(0));

    address DEX = vm.envOr("DEX_ADDRESS", address(0));
    address USDC_GOBLIN_BANK = vm.envOr("USDC_GOBLIN_BANK", address(0));
    address[] PRIVATE_DEPLOYMENT_ROLE_ACCOUNTS = vm.envOr("PRIVATE_DEPLOYMENT_ROLE_ACCOUNTS", ",",  new address[](0));

    address GOBLIN_BANK_ADDRESS;
}
