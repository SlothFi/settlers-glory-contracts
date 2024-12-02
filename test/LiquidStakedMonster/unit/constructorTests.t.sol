// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {LSMTestBase} from "../LSMTestBase.t.sol";
import {LiquidStakedMonster} from "../../../src/LiquidStakedMonster.sol";

/**
 * @title 
 */
contract ConstructorTests is LSMTestBase {

    function setUp() public override {
        super.setUp();
    }

    function testDeployOperatorRoleZero() public {
        vm.expectRevert(LiquidStakedMonster.LiquidStakedMonster__InvalidOperatorRole.selector);
        new LiquidStakedMonster(address(0), defaultAdminRole, marketPlace);
    }

    function testDeployAdminRoleZero() public {
        vm.expectRevert(LiquidStakedMonster.LiquidStakedMonster__InvalidDefaultAdminRole.selector);
        new LiquidStakedMonster(operatorRole, address(0), marketPlace);
    }

    function testDeployMarketPlaceZero() public {
        vm.expectRevert(LiquidStakedMonster.LiquidStakedMonster__InvalidMarketPlace.selector);
        new LiquidStakedMonster(operatorRole, defaultAdminRole, address(0));
    }

    function testDeploy() public {
        new LiquidStakedMonster(operatorRole, defaultAdminRole, marketPlace);
    }

}