// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../../../script/Deployer.s.sol";
import "../../../helper/TestHelper.sol";

contract CompoundV3BaseTest is Deployer, TestHelper {

    event Deposit(address token, uint256 amount);
    event Withdraw(address token, uint256 amount);
    event Collect(address token, uint256 amount);
    event Harvest(address token, uint256 amount);

    CompoundV3Module public yieldModule;

    uint256 public PRECISION;
    uint256 public VERY_SMALL_AMOUNT;
    uint256 public SMALL_AMOUNT;
    uint256 public BIG_AMOUNT;
    address public COMET_TOKEN;
    uint256 public ALL_SHARE_AS_FRACTION;

    function setUp() public {
        loadTestData();

        goblinBank = GoblinBank(payable(address(0x100)));
        deployUniV3();
        deployFeeManager(5000, 5000, 0);

        deployCompoundV3YieldModuleImpl();

        deployCompoundV3YieldModule(address(goblinBank), address(uniV3));

        transferOwnershipFeeManager(OWNER);

        transferOwnershipCompoundV3YieldModule(OWNER);

        yieldModule = compoundV3YieldModule;

        PRECISION = 2;
        uint256 decimals = IERC20Metadata(yieldModule.baseToken()).decimals();
        if (decimals == 18) {
            PRECISION = 10 ** 9;
        }
        VERY_SMALL_AMOUNT = 10 ** IERC20Metadata(yieldModule.baseToken()).decimals() / 10000;
        SMALL_AMOUNT = 1000 * (10 ** IERC20Metadata(yieldModule.baseToken()).decimals());
        BIG_AMOUNT = 100000 * (10 ** IERC20Metadata(yieldModule.baseToken()).decimals());
        if (decimals == 18) {
            VERY_SMALL_AMOUNT = 1000000000000;
        }
        COMET_TOKEN = COMPOUND_V3_COMET_TOKEN;
        ALL_SHARE_AS_FRACTION = 1e18;
    }

    function testInitIsCorrect() public {
        verifyCompoundV3YieldModule(OWNER, address(goblinBank), address(uniV3));
    }

    function testCanDeploy() public {
        address[] memory rewards = new address[](1);
        rewards[0] = COMP;
        CompoundV3Module compoundV3YieldModuleImpl = new CompoundV3Module();
        ERC1967Proxy proxy = new ERC1967Proxy(address(compoundV3YieldModuleImpl), "");
        CompoundV3Module compoundV3YieldModule = CompoundV3Module(payable(proxy));
        compoundV3YieldModule.initialize(address(goblinBank), MANAGER, BASE_TOKEN, COMPOUND_V3_EXECUTION_FEE, address(uniV3),
            rewards, COMET_TOKEN, COMPOUND_V3_REWARDOR, COMPOUND_V3_YIELD_MODULE_NAME, WRAPPED_NATIVE_TOKEN);

        // Deployment revert if the rewardor address is the zero address
        compoundV3YieldModuleImpl = new CompoundV3Module();
        proxy = new ERC1967Proxy(address(compoundV3YieldModuleImpl), "");
        compoundV3YieldModule = CompoundV3Module(payable(proxy));
        vm.expectRevert(bytes("CompoundV3: cannot be the zero address"));
        compoundV3YieldModule.initialize(address(goblinBank), MANAGER, BASE_TOKEN, COMPOUND_V3_EXECUTION_FEE, address(uniV3),
            rewards, COMET_TOKEN, address(0), COMPOUND_V3_YIELD_MODULE_NAME, WRAPPED_NATIVE_TOKEN);

        // Deployment revert if the Comet token address is the zero address
        compoundV3YieldModuleImpl = new CompoundV3Module();
        proxy = new ERC1967Proxy(address(compoundV3YieldModuleImpl), "");
        compoundV3YieldModule = CompoundV3Module(payable(proxy));
        vm.expectRevert(bytes("CompoundV3: cannot be the zero address"));
        compoundV3YieldModule.initialize(address(goblinBank), MANAGER, BASE_TOKEN, COMPOUND_V3_EXECUTION_FEE, address(uniV3),
            rewards, address(0), COMPOUND_V3_REWARDOR, COMPOUND_V3_YIELD_MODULE_NAME, WRAPPED_NATIVE_TOKEN);
    }

    /** helper **/

    function _deposit(address caller, uint256 amount) internal {
        deal(yieldModule.baseToken(), caller, amount);
        vm.startPrank(caller);
        IERC20(yieldModule.baseToken()).approve(address(yieldModule), amount);
        yieldModule.deposit(amount);
        vm.stopPrank();
    }

    function _withdraw(address caller, uint256 shareFraction, address receiver) internal {
        vm.prank(address(caller));
        yieldModule.withdraw(shareFraction, receiver);
    }

    function _harvest(address caller, address receiver) internal {
        vm.prank(address(caller));
        yieldModule.harvest(receiver);
    }
}
