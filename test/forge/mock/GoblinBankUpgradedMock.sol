pragma solidity ^0.8.13;

import "../../../contracts/yield/GoblinBank.sol";

contract GoblinBankUpgradedMock is GoblinBank {

    uint public dummyVersion;

    function initializev2(uint dummy) public {
        dummyVersion = dummy;
    }

    function getDummyVersion() public returns (uint) {
        return dummyVersion;
    }
}
