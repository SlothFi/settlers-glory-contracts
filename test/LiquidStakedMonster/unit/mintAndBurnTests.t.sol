// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {LiquidStakedMonster} from "../../../src/LiquidStakedMonster.sol";
import {LSMTestBase} from "../LSMTestBase.t.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title mintAndBurnTests
 * @dev Tests for minting and burning LiquidStakedMonster tokens
 */
contract mintAndBurnTests is LSMTestBase {

    function setUp() public override {
        super.setUp();
    }

    function testMintWithControllerRole() public {
        uint256 amount = 100 * 10 ** 18;
        address to = makeAddr("recipient");

        _mintLSMTokens(to, amount);

        assertEq(liquidStakedMonster.balanceOf(to), amount);
    }

    function testMintWithControllerRoleToZero() public {
        uint256 amount = 100 * 10 ** 18;
        address to = address(0);

        vm.startPrank(controllerRole);

        vm.expectRevert(LiquidStakedMonster.LiquidStakedMonster__NoZeroAddress.selector);
        liquidStakedMonster.mint(to, amount);
    }

    function testMintWithControllerRoleZeroAmount() public {
        uint256 amount = 0;
        address to = makeAddr("recipient");

        vm.startPrank(controllerRole);

        vm.expectRevert(LiquidStakedMonster.LiquidStakedMonster__NoZeroAmount.selector);
        liquidStakedMonster.mint(to, amount);
    }

    function testMintWithoutControllerRole() public {
        uint256 amount = 100 * 10 ** 18;
        address to = makeAddr("recipient");

        // vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, controllerRole, keccak256("CONTROLLER_ROLE")));
        vm.expectRevert();
        liquidStakedMonster.mint(to, amount);
    }

    function testBurnWithControllerRole() public {
        uint256 amount = 100 * 10 ** 18;
        address from = makeAddr("holder");

        _mintLSMTokens(from, amount);

        _burnLSMTokens(from, amount);

        assertEq(liquidStakedMonster.balanceOf(from), 0);
    }

    function testBurnWithControllerRoleFromZero() public {
        uint256 amount = 100 * 10 ** 18;
        address from = address(0);

        vm.startPrank(controllerRole);

        vm.expectRevert(LiquidStakedMonster.LiquidStakedMonster__NoZeroAddress.selector);
        liquidStakedMonster.burn(from, amount);
    }

    function testBurnWithControllerRoleZeroAmount() public {
        uint256 amount = 0;
        address from = makeAddr("holder");

        vm.startPrank(controllerRole);

        vm.expectRevert(LiquidStakedMonster.LiquidStakedMonster__NoZeroAmount.selector);
        liquidStakedMonster.burn(from, amount);
    }

    function testBurnWithoutControllerRole() public {
        uint256 amount = 100 * 10 ** 18;
        address from = makeAddr("holder");

        _mintLSMTokens(from, amount);

        // vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, controllerRole, keccak256("CONTROLLER_ROLE")));
        vm.expectRevert();
        vm.startPrank(nonControllerRole);
        liquidStakedMonster.burn(from, amount);
        vm.stopPrank();
    }

    function testMintToMarketplace() public {
        uint256 amount = 100 * 10 ** 18;

        _mintLSMTokens(marketPlace, amount);

        assertEq(liquidStakedMonster.balanceOf(marketPlace), amount);
    }

    function testMintToNonMarketPlace() public {
        uint256 amount = 100 * 10 ** 18;
        address to = makeAddr("recipient");

        _mintLSMTokens(to, amount);

        assertEq(liquidStakedMonster.balanceOf(to), amount);
    }

    function testburnFromMarketplace() public {
        uint256 amount = 100 * 10 ** 18;

        _mintLSMTokens(marketPlace, amount);

        _burnLSMTokens(marketPlace, amount);

        assertEq(liquidStakedMonster.balanceOf(marketPlace), 0);
    }

    function testburnFromNoneMarketPlace() public {
        uint256 amount = 100 * 10 ** 18;
        address from = makeAddr("holder");

        _mintLSMTokens(from, amount);

        _burnLSMTokens(from, amount);

        assertEq(liquidStakedMonster.balanceOf(from), 0);
    }

    function _mintLSMTokens(address to, uint256 amount) internal {
        vm.startPrank(controllerRole);
        liquidStakedMonster.mint(to, amount);
        vm.stopPrank();
    }

    function _burnLSMTokens(address from, uint256 amount) internal {
        vm.startPrank(controllerRole);
        liquidStakedMonster.burn(from, amount);
        vm.stopPrank();
    }
}