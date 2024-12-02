// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {MonERC721TestBase} from "../MonERC721TestBase.t.sol";
import {MonERC721} from "../../../src/MonERC721.sol";
import {MockMonsterToken} from "../../../src/mocks/MockMonsterToken.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

/**
 * @title mintTests
 * @dev Tests for minting MonERC721 tokens
 */
contract mintTests is MonERC721TestBase {

    function setUp() public override {
        super.setUp();
    }

    function testMintWithNativeTokenSuccessUser() public {
        uint256 amount = priceInNativeToken;

        vm.startPrank(user);
        monERC721.mintWithNativeToken{value: amount}();
        vm.stopPrank();

        assertEq(monERC721.balanceOf(user), 1);
        assertEq(monERC721.ownerOf(1), user);
    }

    function testMintWithNativeTokenSuccessContract() public {
        uint256 amount = priceInNativeToken;

        vm.startPrank(mockERC721Receiver);
        monERC721.mintWithNativeToken{value: amount}();

        assertEq(monERC721.balanceOf(mockERC721Receiver), 1);
        assertEq(monERC721.ownerOf(1), mockERC721Receiver);
    }

    function testMintWithNativeTokenRefund() public {
        uint256 amount = priceInNativeToken + 1;
       
        uint256 initialBalance = user.balance;

        vm.startPrank(user);
        monERC721.mintWithNativeToken{value: amount}();
        vm.stopPrank();


        assertEq(monERC721.balanceOf(user), 1);
        assertEq(monERC721.ownerOf(1), user);
        assertEq(user.balance, initialBalance - priceInNativeToken);
    }

    function testMintWithNativeTokenRefundFail() public {
        uint256 amount = priceInNativeToken + 1;
       
        vm.startPrank(mockRevertOnReceiveContract);
        vm.expectRevert(MonERC721.MonERC721__NativeTransferFailed.selector);
        monERC721.mintWithNativeToken{value: amount}();
    }

    function testMintWithNativeTokenNotEnough() public {
        uint256 amount = priceInNativeToken - 1;

        vm.startPrank(user);
        vm.expectRevert(MonERC721.MonERC721__NotEnoughNativeTokens.selector);
        monERC721.mintWithNativeToken{value: amount}();
    }

    function testMintWithNativeTokenMaxSupplyReached() public {
        uint256 amount = priceInNativeToken;

        vm.startPrank(user);
        for (uint256 i = 0; i < maxSupply; i++) {
            monERC721.mintWithNativeToken{value: amount}();
        }

        vm.expectRevert(MonERC721.MonERC721__MaxSupplyReached.selector);
        monERC721.mintWithNativeToken{value: amount}();
    }

    function testMintWithMonsterTokenSuccessUser() public {
        uint256 amount = priceInMonsterToken;

        vm.startPrank(user);
        monsterToken.approve(address(monERC721), amount);
        monERC721.mintWithMonsterToken();
        vm.stopPrank();

        assertEq(monERC721.balanceOf(user), 1);
        assertEq(monERC721.ownerOf(1), user);
    }

    function testMintWithMonsterTokenSuccessContract() public {
        uint256 amount = priceInMonsterToken;

        vm.startPrank(mockERC721Receiver);
        monsterToken.approve(address(monERC721), amount);
        monERC721.mintWithMonsterToken();
        vm.stopPrank();

        assertEq(monERC721.balanceOf(mockERC721Receiver), 1);
        assertEq(monERC721.ownerOf(1), mockERC721Receiver);
    }

    function testMintWithMonsterTokenNotEnoughApproved() public {
        uint256 amount = priceInMonsterToken - 1;

        vm.startPrank(user);
        monsterToken.approve(address(monERC721), amount);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, monERC721, 0, 1));
        monERC721.mintWithMonsterToken();
    }

    function testMintWithMonsterTokenMaxSupplyReached() public {
        uint256 amount = priceInMonsterToken;

        vm.startPrank(user);
        // Mint up to max supply
        for (uint256 i = 0; i < maxSupply; i++) {
            monsterToken.approve(address(monERC721), amount);
            monERC721.mintWithMonsterToken();
        }

        // Attempt to mint beyond max supply
        monsterToken.approve(address(monERC721), amount);
        vm.expectRevert(MonERC721.MonERC721__MaxSupplyReached.selector);
        monERC721.mintWithMonsterToken();
    }
}