// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {MonERC721TestBase} from "../MonERC721TestBase.t.sol";
import {MonERC721} from "../../../src/MonERC721.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
/**
 * @title withdrawTests
 * @dev Tests for withdrawing native tokens and monster tokens in MonERC721
 */
contract withdrawTests is MonERC721TestBase {

    function setUp() public override {
        super.setUp();
    }

    function testWithdrawNativeTokensSuccess() public {
        uint256 amount = 1 ether;

        // Send some native tokens to the contract
        vm.deal(address(monERC721), amount);

        uint256 initialBalance = address(fundsWallet).balance;

        vm.startPrank(owner);
        monERC721.withdrawNativeTokens(amount);
        vm.stopPrank();

        assertEq(address(fundsWallet).balance, initialBalance + amount);
    }

    function testWithdrawNativeTokensMaxSuccess() public {
        uint256 amount = 1 ether;

        // Send some native tokens to the contract
        vm.deal(address(monERC721), amount);

        uint256 initialBalance = address(fundsWallet).balance;

        vm.startPrank(owner);
        monERC721.withdrawNativeTokens(type(uint256).max);
        vm.stopPrank();

        assertEq(address(fundsWallet).balance, initialBalance + amount);
    }

    function testWithdrawNativeTokensZeroAmount() public {
        vm.startPrank(owner);
        vm.expectRevert(MonERC721.MonERC721__NoZeroAmount.selector);
        monERC721.withdrawNativeTokens(0);
        vm.stopPrank();
    }

    function testWithdrawNativeTokensNotEnough() public {
        uint256 amount = 1 ether;

        // Send some native tokens to the contract
        vm.deal(address(monERC721), amount / 2);

        vm.startPrank(owner);
        vm.expectRevert(MonERC721.MonERC721__NotEnoughNativeTokens.selector);
        monERC721.withdrawNativeTokens(amount);
        vm.stopPrank();
    }

    function testWithdrawNativeTokensNotOwner() public {
        uint256 amount = 1 ether;

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector,user));
        monERC721.withdrawNativeTokens(amount);
    }

    function testWithdrawMonsterTokensSuccess() public {
        uint256 amount = 1000;

        // Send some monster tokens to the contract
        monsterToken.transfer(address(monERC721), amount);

        uint256 initialBalance = monsterToken.balanceOf(fundsWallet);

        vm.startPrank(owner);
        monERC721.withdrawMonsterTokens(amount);
        vm.stopPrank();

        assertEq(monsterToken.balanceOf(fundsWallet), initialBalance + amount);
    }

    function testWithdrawMonsterTokensMaxSuccess() public {
        uint256 amount = 1000;

        // Send some monster tokens to the contract
        monsterToken.transfer(address(monERC721), amount);

        uint256 initialBalance = monsterToken.balanceOf(fundsWallet);

        vm.startPrank(owner);
        monERC721.withdrawMonsterTokens(type(uint256).max);
        vm.stopPrank();

        assertEq(monsterToken.balanceOf(fundsWallet), initialBalance + amount);
    }

    function testWithdrawMonsterTokensZeroAmount() public {
        vm.startPrank(owner);
        vm.expectRevert(MonERC721.MonERC721__NoZeroAmount.selector);
        monERC721.withdrawMonsterTokens(0);
        vm.stopPrank();
    }

    function testWithdrawMonsterTokensNotEnough() public {
        uint256 amount = 1000;

        // Send some monster tokens to the contract
        monsterToken.transfer(address(monERC721), amount / 2);

        vm.startPrank(owner);
        vm.expectRevert(MonERC721.MonERC721__NotEnoughMonterTokens.selector);
        monERC721.withdrawMonsterTokens(amount);
        vm.stopPrank();
    }

    function testWithdrawMonsterTokensNotOwner() public {
        uint256 amount = 1000;

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector,user));
        monERC721.withdrawMonsterTokens(amount);
    }
}