pragma solidity ^0.8.13;

import "../../../contracts/dex/UniV3DexModule.sol";

contract UniswapV3UpgradedMock is UniV3DexModule {

    uint public dummyVersion;

    function initializev2(uint dummy) public {
        dummyVersion = dummy;
    }

    function getDummyVersion() public returns (uint) {
        return dummyVersion;
    }
}
