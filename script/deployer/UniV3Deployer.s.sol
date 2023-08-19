// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "../DataLoader.s.sol";
import "../../contracts/dex/UniV3DexModule.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UniV3Deployer is DataLoader {
    UniV3DexModule public uniV3Impl;
    UniV3DexModule public uniV3;

    function setUniV3Dex() internal {
        uniV3 = UniV3DexModule(payable(DEX));
    }

    function deployUniV3DexImplem() internal {
        uniV3Impl = new UniV3DexModule();
    }

    function deployUniV3Dex() internal {
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(uniV3Impl),
            ""
        );
        uniV3 = UniV3DexModule(payable(proxy));
        uniV3.initialize(routes);
    }

    function deployUniV3() internal {
        deployUniV3DexImplem();
        deployUniV3Dex();
    }

    function transferOwnershipUniV3Dex(address transferTo) internal {
        uniV3.transferOwnership(transferTo);
    }

    function verifyUniV3Dex(address owner) internal {
        assertEq(
            address(uniV3) != 0x0000000000000000000000000000000000000000,
            true
        );
        assertEq(uniV3.owner(), owner);
        assertEq(address(uniV3.swapRouter()), UNISWAP_V3_ROUTER);
        for (uint256 i = 0; i < routes.length; i++) {
            assertEq(
                uniV3.getRoute(routes[i][0], routes[i][routes[i].length - 1]),
                routes[i]
            );
            assertGt(
                IERC20(routes[i][0]).allowance(address(uniV3), UNISWAP_V3_ROUTER),
                type(uint256).max / 2
            );
        }
    }

    function printUniV3DexStorage() internal view {
        console.log("\nUni V3 Dex storage");
        console.log("UniV3 Dex :              ", address(uniV3));
        console.log("Owner:              ", uniV3.owner());
        console.log("Router:             ", address(uniV3.swapRouter()));
        // TODO: if needed, find a clean way to pretty print the paths
    }
}
