pragma solidity ^0.8.0;

import "../contracts/yield/interface/IGoblinBank.sol";
import "../contracts/yield/interface/IYieldModule.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract AddressFetcher {
    address public goblinBankAddress;
    address public goblinBankImplAddress;
    address public earnVaultAddress;
    address public earnVaultImplAddress;
    address public stargateModuleAddress;
    address public stargateModuleImplAddress;
    address public compoundV3ModuleAddress;
    address public compoundV3ModuleImplAddress;
    address public aaveModuleAddress;
    address public aaveModuleImplAddress;

    bool STARGATE_ACTIVE_CURRENT_VALUE;
    bool AAVE_ACTIVE_CURRENT_VALUE;
    bool COMPOUND_V3_ACTIVE_CURRENT_VALUE;

    bytes32 private STARGATE_YIELD_MODULE = keccak256(bytes("StargateYieldModule"));
    bytes32 private AAVE_YIELD_MODULE = keccak256(bytes("AaveV3YieldModule"));
    bytes32 private COMPOUND_V3_YIELD_MODULE = keccak256(bytes("CompoundV3YieldModule"));

    function fetchAddresses(address _goblinBankAddress) public {
        goblinBankAddress = _goblinBankAddress;
        goblinBankImplAddress = IGoblinBank(goblinBankAddress).getImplementation();
        uint256 numberOfModules = IGoblinBank(goblinBankAddress).numberOfModules();
        for (uint256 i = 0; i < numberOfModules; i++) {
            (IYieldModule module,) = IGoblinBank(goblinBankAddress).yieldOptions(i);
            bytes32 moduleName = keccak256(bytes(module.name()));
            if (moduleName == STARGATE_YIELD_MODULE){
                stargateModuleAddress = address(module);
                stargateModuleImplAddress = module.getImplementation();
                STARGATE_ACTIVE_CURRENT_VALUE = true;
            } else if (moduleName == AAVE_YIELD_MODULE){
                aaveModuleAddress = address(module);
                aaveModuleImplAddress = module.getImplementation();
                AAVE_ACTIVE_CURRENT_VALUE = true;
            } else if (moduleName == COMPOUND_V3_YIELD_MODULE){
                compoundV3ModuleAddress = address(module);
                compoundV3ModuleImplAddress = module.getImplementation();
                COMPOUND_V3_ACTIVE_CURRENT_VALUE = true;
            } else {
                revert("AddressFetcher: unknown module");
            }
        }
    }

}
