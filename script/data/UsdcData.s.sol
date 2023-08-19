pragma solidity ^0.8.0;

import "./CommonData.s.sol";
import "./TokenData.s.sol";

contract UsdcData is CommonData, TokenData {

    function loadUsdcData() public {
        // Common
        BASE_TOKEN = USDC;
        BASE_TOKEN_ORACLE = CHAINLINK_USDC;
        WRAPPED_NATIVE_TOKEN = address(0xdead);

        // Active module
        STARGATE_ACTIVE = true;
        AAVE_ACTIVE = true;
        COMPOUND_V3_ACTIVE = true;

        // Allocation
        STARGATE_ALLOCATION = 5000;
        AAVE_ALLOCATION = 4000;
        COMPOUND_V3_ALLOCATION = 1000;

        // Goblin Bank
        SM_NAME = "Goblin Bank USDC.e";
        SM_SYMBOL = "gbUSDC.e";
        SM_MIN_HARVEST_THRESHOLD_IN_BASE_TOKEN = 50000; // 1 USDC
        SM_PERFORMANCE_FEE = 2000;
        SM_CAP = 500000000000; // 500k USDC
        SM_MIN_AMOUNT = 10000000; // 10 USDC ~= 10 USD

        // Stargate
        STARGATE_EXECUTION_FEE = 300000000000000000;
        STARGATE_POOL = STARGATE_USDC_POOL;
        STARGATE_ROUTER_POOL_ID = STARGATE_ROUTER_USDC_POOL_ID;
        STARGATE_LP_STAKING_POOL_ID = STARGATE_LP_STAKING_USDC_POOL_ID;
        STARGATE_REDEEM_FROM_CHAIN_ID = 106;
        STARGATE_LP_PROFIT_WITHDRAWL_THRESHOLD_IN_BASE_TOKEN = 1000000; // 1 USDC
        STARGATE_YIELD_MODULE_NAME = "StargateYieldModule";

        // Aave
        AAVE_EXECUTION_FEE = 0;
        AAVE_A_TOKEN = AAVE_A_USDC;
        AAVE_YIELD_MODULE_NAME = "AaveV3YieldModule";

        // Compound V3
        COMPOUND_V3_EXECUTION_FEE = 0;
        COMPOUND_V3_COMET_TOKEN = COMPOUND_V3_USDC;
        COMPOUND_V3_YIELD_MODULE_NAME = "CompoundV3YieldModule";

        TEAM_SHARE = 3000;
        TREASURY_SHARE = 2000;
        STAKING_SHARE = 5000;
    }
}
