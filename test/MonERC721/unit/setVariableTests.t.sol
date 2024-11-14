// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {MonERC721TestBase} from "../MonERC721TestBase.t.sol";
import {MonERC721} from "../../../src/MonERC721.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
/**
 * @title setVariableTests
 * @dev Tests for setting variables in MonERC721
 */
contract setVariableTests is MonERC721TestBase {

    function setUp() public override {
        super.setUp();
    }

    function testSetFundsWalletWithOwner() public {
        address newFundsWallet = makeAddr("newFundsWallet");

        vm.startPrank(owner);
        monERC721.setFundsWallet(newFundsWallet);
        vm.stopPrank();

        assertEq(monERC721.fundsWallet(), newFundsWallet);
    }

    function testSetInvalidFundsWallet() public {
        address newFundsWallet = address(0);

        vm.startPrank(owner);
        vm.expectRevert(MonERC721.MonERC721__InvalidWallet.selector);
        monERC721.setFundsWallet(newFundsWallet);
    }

    function testSetFundsWalletWithoutOwner() public {
        address newFundsWallet = makeAddr("newFundsWallet");

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector,user));
        monERC721.setFundsWallet(newFundsWallet);
    }

    function testSetBaseUriWithOwner() public {
        string memory newBaseUri = "https://newapi.defimons.com/mon/";

        vm.startPrank(owner);
        monERC721.setBaseUri(newBaseUri);
        vm.stopPrank();

        assertEq(monERC721.baseUri(), newBaseUri);
    }

    function testSetInvalidBaseUri() public {
        string memory newBaseUri = "";

        vm.startPrank(owner);
        vm.expectRevert(MonERC721.MonERC721__InvalidBaseUri.selector);
        monERC721.setBaseUri(newBaseUri);
    }

    function testSetBaseUriWithoutOwner() public {
        string memory newBaseUri = "https://newapi.defimons.com/mon/";

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector,user));
        monERC721.setBaseUri(newBaseUri);
    }
    
}