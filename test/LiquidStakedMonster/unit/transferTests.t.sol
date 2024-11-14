// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {LSMTestBase} from "../LSMTestBase.t.sol";
import {LiquidStakedMonster} from "../../../src/LiquidStakedMonster.sol";
import {MockStakingContract} from "../helper/MockStakingContract.t.sol";

/**
 * @title transferTests
 * @dev Tests for transferring LiquidStakedMonster tokens
 */
contract transferTests is LSMTestBase {

    function setUp() public override {
        super.setUp();
    }

    function testTransferToMarketplace() public {
        uint256 amount = 100 * 10 ** 18;
        address from = makeAddr("holder");

        _mintLSMTokens(from, amount);

        _transferLSMTokens(from, marketPlace, amount);

        assertEq(liquidStakedMonster.balanceOf(marketPlace), amount);
        assertEq(liquidStakedMonster.balanceOf(from), 0);
    }

    function testTransferToNonMarketplace() public {
        uint256 amount = 100 * 10 ** 18;
        address from = makeAddr("holder");
        address to = makeAddr("recipient");

        _mintLSMTokens(from, amount);

        // Attempt to transfer tokens to a non-marketplace address
        vm.startPrank(from);
        vm.expectRevert(LiquidStakedMonster.LiquidStakedMonster__TokenNotTransferable.selector);
        liquidStakedMonster.transfer(amount, to);
    }

    function testTransferFromToMarketplace() public {
        uint256 amount = 100 * 10 ** 18;
        address from = makeAddr("holder");

       _mintLSMTokens(from, amount);

        _approveLSMTokens(from, marketPlace, amount);

        _transferFromLSMTokens(from, marketPlace, amount);

        assertEq(liquidStakedMonster.balanceOf(marketPlace), amount);
        assertEq(liquidStakedMonster.balanceOf(from), 0);
    }

    function testTransferFromToNonMarketplace() public {
        uint256 amount = 100 * 10 ** 18;
        address from = makeAddr("holder");
        address to = makeAddr("recipient");

        _mintLSMTokens(from, amount);

        _approveLSMTokens(from, to, amount);

        // Attempt to transfer tokens from the holder to a non-marketplace address
        vm.startPrank(to);
        vm.expectRevert(LiquidStakedMonster.LiquidStakedMonster__TokenNotTransferable.selector);
        liquidStakedMonster.transferFrom(from, to, amount);
    }

    function testCustomTransferToMarketplace() public {
        uint256 amount = 100 * 10 ** 18;
        address from = makeAddr("holder");

        _mintLSMTokens(from, amount);

        vm.expectCall(
            address(stakingContact),
            abi.encodeWithSelector(
                MockStakingContract(stakingContact).updateStakingBalance.selector,
                from,
                marketPlace,
                amount
            )
        );
        _customTransferLSMTokens(amount, from, marketPlace);

        assertEq(liquidStakedMonster.balanceOf(marketPlace), amount);
        assertEq(liquidStakedMonster.balanceOf(from), 0);
    }

    function testCustomTransferToNonMarketplace() public {
        uint256 amount = 100 * 10 ** 18;
        address from = makeAddr("holder");
        address to = makeAddr("recipient");

        _mintLSMTokens(from, amount);

        // Attempt to transfer tokens to a non-marketplace address
        vm.startPrank(from);
        vm.expectRevert(LiquidStakedMonster.LiquidStakedMonster__TokenNotTransferable.selector);
        liquidStakedMonster.transfer(amount, to);
    }

    function testCustomTransferFromMarketplaceToNonMarketplace() public {
        uint256 amount = 100 * 10 ** 18;

        _mintLSMTokens(marketPlace, amount);

        _approveLSMTokens(marketPlace, nonMarketplace, amount);

        vm.startPrank(nonMarketplace);
        vm.expectRevert(LiquidStakedMonster.LiquidStakedMonster__TokenNotTransferable.selector);
        liquidStakedMonster.transferFrom(amount, marketPlace, nonMarketplace);
    }

    function testCustomTransferFromMaketplaceToMarketplace() public {
        uint256 amount = 100 * 10 ** 18;

        _mintLSMTokens(marketPlace, amount);

        _approveLSMTokens(marketPlace, marketPlace, amount);

        vm.expectCall(
            address(stakingContact),
            abi.encodeWithSelector(
                MockStakingContract(stakingContact).updateStakingBalance.selector,
                marketPlace,
                marketPlace,
                amount
            )
        );

        _customTransferFromLSMTokens(amount, marketPlace, marketPlace);

        assertEq(liquidStakedMonster.balanceOf(marketPlace), amount);
    }

    function testCustomTransferFromNonMarketplace() public {
        uint256 amount = 100 * 10 ** 18;
        address to = makeAddr("recipient");

        _mintLSMTokens(nonMarketplace, amount);

        _approveLSMTokens(nonMarketplace, to, amount);

        // Attempt to transfer tokens from the holder to a non-marketplace address
        vm.startPrank(to);
        vm.expectRevert(LiquidStakedMonster.LiquidStakedMonster__TokenNotTransferable.selector);
        liquidStakedMonster.transferFrom(amount, nonMarketplace, to);
    }

    function _mintLSMTokens(address from, uint amount) internal{
        vm.startPrank(controllerRole);
        liquidStakedMonster.mint(from, amount);
        vm.stopPrank();
    }

    function _approveLSMTokens(address from, address to, uint amount) internal{
        vm.startPrank(from);
        liquidStakedMonster.approve(to, amount);
        vm.stopPrank();
    }

    function _transferLSMTokens(address from, address to, uint amount) internal{
        vm.startPrank(from);
        liquidStakedMonster.transfer(to, amount);
        vm.stopPrank();
    }

    function _transferFromLSMTokens(address from, address to, uint amount) internal{
        vm.startPrank(to);
        liquidStakedMonster.transferFrom(from, to, amount);
        vm.stopPrank();
    }

    function _customTransferLSMTokens(uint amount, address from, address to) internal{
        vm.startPrank(from);
        liquidStakedMonster.transfer(amount, to);
        vm.stopPrank();
    }

    function _customTransferFromLSMTokens(uint amount, address from, address to) internal{
        vm.startPrank(to);
        liquidStakedMonster.transferFrom(amount, from, to);
        vm.stopPrank();
    }
}