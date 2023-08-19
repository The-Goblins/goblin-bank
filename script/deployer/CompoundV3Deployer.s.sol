// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DataLoader.s.sol";
import "../AddressFetcher.s.sol";
import "../../contracts/yield/module/CompoundV3Module.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract CompoundV3Deployer is DataLoader, AddressFetcher {
    CompoundV3Module public compoundV3YieldModuleImpl;
    CompoundV3Module public compoundV3YieldModule;

    function setCompoundV3YieldModuleImpl() internal {
        compoundV3YieldModuleImpl = CompoundV3Module(payable(compoundV3ModuleImplAddress));
    }

    function setCompoundV3YieldModule() internal {
        compoundV3YieldModule = CompoundV3Module(payable(compoundV3ModuleAddress));
    }

    function deployCompoundV3YieldModuleImpl() internal {
        compoundV3YieldModuleImpl = new CompoundV3Module();
    }

    function deployCompoundV3YieldModule(address smartFarmooor, address dex) internal {
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(compoundV3YieldModuleImpl),
            ""
        );
        compoundV3YieldModule = CompoundV3Module(payable(proxy));

        address[] memory rewards = new address[](1);
        rewards[0] = COMP;

        compoundV3YieldModule.initialize(
            smartFarmooor,
            MANAGER,
            BASE_TOKEN,
            COMPOUND_V3_EXECUTION_FEE,
            dex,
            rewards,
            COMPOUND_V3_COMET_TOKEN,
            COMPOUND_V3_REWARDOR,
            COMPOUND_V3_YIELD_MODULE_NAME,
            WRAPPED_NATIVE_TOKEN);
    }

    function transferOwnershipCompoundV3YieldModule(address transferTo) internal {
        compoundV3YieldModule.transferOwnership(transferTo);
    }

    function verifyCompoundV3YieldModule(address owner, address smartFarmooor, address dex) internal {
        assertEq(
            address(compoundV3YieldModule) !=
            0x0000000000000000000000000000000000000000,
            true
        );
        assertEq(
            compoundV3YieldModule.getImplementation(),
            address(compoundV3YieldModuleImpl)
        );
        assertEq(compoundV3YieldModule.owner(), owner);
        assertEq(compoundV3YieldModule.manager(), MANAGER);
        assertEq(compoundV3YieldModule.goblinBank(), smartFarmooor);
        assertEq(compoundV3YieldModule.baseToken(), BASE_TOKEN);
        assertEq(compoundV3YieldModule.executionFee(), COMPOUND_V3_EXECUTION_FEE);
        assertEq(address(compoundV3YieldModule.dex()), dex, "compoundV3YieldModule.dex() != dex");
        assertEq(compoundV3YieldModule.rewards(0), COMP);
        assertEq(compoundV3YieldModule.name(), COMPOUND_V3_YIELD_MODULE_NAME);
        // Max approval for QI token is type(uint96).max
        assertGt(
            IERC20(COMP).allowance(address(compoundV3YieldModule), dex),
            type(uint96).max / 2
        );
        assertEq(compoundV3YieldModule.cometToken(), COMPOUND_V3_COMET_TOKEN);

        assertGt(
            IERC20(BASE_TOKEN).allowance(address(compoundV3YieldModule), COMPOUND_V3_COMET_TOKEN),
            type(uint256).max / 2
        );
    }

    function printCompoundV3Storage() internal view {
        console.log("\nCompound V3 yield module storage");
        console.log("Implementation:     ", compoundV3YieldModule.getImplementation());
        console.log("Owner:              ", compoundV3YieldModule.owner());
        console.log("Manager:            ", compoundV3YieldModule.manager());
        console.log("Goblin bank:     ", compoundV3YieldModule.goblinBank());
        console.log("baseToken:          ", compoundV3YieldModule.baseToken());
        console.log("Execution fee:      ", compoundV3YieldModule.executionFee());
        console.log("Dex:                ", address(compoundV3YieldModule.dex()));
        console.log("Reward0:            ", compoundV3YieldModule.rewards(0));
        console.log("Name:               ", compoundV3YieldModule.name());
        console.log("CometToken:         ", compoundV3YieldModule.cometToken());
        console.log("Comp Rewardor:      ", compoundV3YieldModule.compRewardor());
    }
}
