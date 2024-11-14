// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {LSMTestBase} from "../LSMTestBase.t.sol";
import {LiquidStakedMonster} from "../../../src/LiquidStakedMonster.sol";

/**
 * @title transferTests
 * @dev Tests for transferring LiquidStakedMonster tokens
 */
contract setMarketplaceTests is LSMTestBase {

    function setUp() public override {
        super.setUp();
    }

    function testSetMarketplaceWithOperatorRole() public {
        address newMarketPlace = makeAddr("newMarketPlace");

        vm.startPrank(operatorRole);
        liquidStakedMonster.setMarketPlace(newMarketPlace);
        vm.stopPrank();

        assertEq(liquidStakedMonster.s_marketPlace(), newMarketPlace);
    }

    function testSetMarketplaceWithOperatorRoleToZero() public {
        
        vm.startPrank(operatorRole);
        
        vm.expectRevert(LiquidStakedMonster.LiquidStakedMonster__NoZeroAddress.selector);
        liquidStakedMonster.setMarketPlace(address(0));
    }

    function testSetMarketplaceWithoutControllerRole() public {
        address newMarketPlace = makeAddr("newMarketPlace");

        vm.expectRevert();
        liquidStakedMonster.setMarketPlace(newMarketPlace);
    }

}