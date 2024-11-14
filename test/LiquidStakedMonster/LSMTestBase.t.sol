// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {LiquidStakedMonster} from "../../src/LiquidStakedMonster.sol";
import {MockStakingContract} from "./helper/MockStakingContract.t.sol";

/**
 * @title MonERC721TestBase
 * @dev Base contract for MonERC721 tests
 * @dev Contains common setup logic
 */
contract LSMTestBase is Test {
    LiquidStakedMonster public liquidStakedMonster;

    address public nonControllerRole = makeAddr("nonControllerRole");
    address public nonOperatorRole = makeAddr("nonOperatorRole");
    address public nonMarketplace = makeAddr("nonMarketplace");

    address public marketPlace = makeAddr("marketPlace");

    // the controller role is msg.sender , also the staking contract so they need to be both
    address public controllerRole = address(new MockStakingContract());
    address public stakingContact = controllerRole;

    address public operatorRole = makeAddr("operatorRole");
    address public defaultAdminRole = makeAddr("defaultAdminRole");

    function setUp() public virtual {
        vm.startPrank(controllerRole);
        liquidStakedMonster = new LiquidStakedMonster(
            operatorRole,
            defaultAdminRole,
            marketPlace
        );
        vm.stopPrank();
    }
}
