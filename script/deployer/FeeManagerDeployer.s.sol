// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "../DataLoader.s.sol";
import "../../contracts/dex/UniV3DexModule.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../contracts/common/FeeManager.sol";

contract FeeManagerDeployer is DataLoader {
    FeeManager public feeManager;

    function deployFeeManager(uint16 _teamShare, uint16 _treasuryShare, uint16 _stakingShare) internal {
        feeManager = new FeeManager(_teamShare, _treasuryShare, _stakingShare, TEAM_ADDRESS, TREASURY_ADDRESS, STAKING_ADDRESS);
    }

    function transferOwnershipFeeManager(address transferTo) internal {
        feeManager.transferOwnership(transferTo);
    }

    function verifyFeeManager(address owner) internal {
        assertEq(
            address(feeManager) != 0x0000000000000000000000000000000000000000,
            true
        );
        assertEq(feeManager.owner(), owner);
    }

    function printFeeManagerDexStorage() internal view {
        console.log("\nFeeManager storage");
        console.log("FeeManager :    ", address(feeManager));
        console.log("Owner:              ", feeManager.owner());
        console.log("Team:               ", feeManager.team());
        console.log("Staking:            ", feeManager.staking());
        console.log("Treasury:           ", feeManager.treasury());
        console.log("TeamShare:          ", feeManager.teamShare());
        console.log("StakingShare:       ", feeManager.stakingShare());
        console.log("TreasuryShare:      ", feeManager.treasuryShare());
        // TODO: if needed, find a clean way to pretty print the paths
    }
}
