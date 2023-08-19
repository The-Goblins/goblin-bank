pragma solidity ^0.8.0;

import "./CommonData.s.sol";

contract DexData is CommonData {
    address[] public DEX_WETH_USDC_ROUTE = [WETH, USDC];
    address[] public DEX_STG_USDC_ROUTE = [STG, USDC];

    address[][] public routes = [
    DEX_WETH_USDC_ROUTE,
    DEX_STG_USDC_ROUTE
    ];
}
