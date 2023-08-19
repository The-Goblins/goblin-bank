pragma solidity ^0.8.0;

import "forge-std/console.sol";
import "forge-std/Vm.sol";
import "forge-std/Script.sol";
import "forge-std/Test.sol";

import "./data/EnvData.s.sol";
import "./data/TestData.s.sol";
import "./data/CommonData.s.sol";
import "./data/TimelockData.s.sol";
import "./data/DexData.s.sol";
import "./data/UsdcData.s.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DataLoader is Script, Test, EnvData, TestData, CommonData, TimelockData, DexData, UsdcData {

    /*
    Rules
    - EOA and multisig are stored in capitalized variable, e.g., OWNER, MANAGER, DEPLOYER, etc
    - Contracts are stored in object, even if it already deployed on stage or prod, e.g., timelock, smartFarmooor, dex, etc
    */

    // This function should only used when interacting with prod or stage
    function loadData() public {
        // We check here that the environment variables have been properly set.
        // If one of the variable is the default value (zero, empty string, etc),
        // it means that the .env is not correctly set.
        require(keccak256(bytes(BASE_TOKEN_NAME)) != keccak256(bytes(string(""))), "BASE_TOKEN_NAME must not be empty");
        require(TIMELOCK != address(0), "TIMELOCK != address(0)");
        require(OWNER != address(0), "OWNER != address(0)");
        require(MANAGER != address(0), "MANAGER != address(0)");
        require(DEPLOYER != address(0), "DEPLOYER != address(0)");

        require(TEAM_ADDRESS != address(0), "TEAM_ADDRESS != address(0)");
        require(TREASURY_ADDRESS != address(0), "TREASURY_ADDRESS != address(0)");
        require(STAKING_ADDRESS != address(0), "STAKING_ADDRESS != address(0)");

        //require(DEX != address(0), "DEX != address(0)");

        _loadData(false);

        //require(GOBLIN_BANK_ADDRESS != address(0), "GOBLIN_BANK_ADDRESS != address(0)");
    }

    // This function should only be used by tests
    function loadTestData() public {
        require(keccak256(bytes(BASE_TOKEN_NAME)) != keccak256(bytes(string(""))));

        // If needed, the below components are deployed in tests
        TIMELOCK = address(0);
        DEX = address(0);
        USDC_GOBLIN_BANK = address(0);

        // We override these data when we deploy contract for test such that the addresses are deterministic
        OWNER = makeAddr("OWNER");
        MANAGER = makeAddr("MANAGER");
        DEPLOYER = makeAddr("DEPLOYER");

        TREASURY_ADDRESS = makeAddr("TREASURY_ADDRESS");
        TEAM_ADDRESS = makeAddr("TEAM_ADDRESS");
        STAKING_ADDRESS = makeAddr("STAKING_ADDRESS");

        _loadData(true);
    }

    function _loadData(bool isTest) private {
        loadTimelockData(OWNER, MANAGER);

        address treasury = OWNER;
        address team = OWNER;
        address staking = OWNER;

        if (keccak256(bytes(BASE_TOKEN_NAME)) == keccak256(bytes("USDC"))) {
            //require(isTest || USDC_GOBLIN_BANK != address(0), "USDC_GOBLIN_BANK != address(0)");
            //GOBLIN_BANK_ADDRESS = USDC_GOBLIN_BANK;
            loadUsdcData();
        }
    }
}
