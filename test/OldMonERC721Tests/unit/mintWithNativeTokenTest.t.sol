// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {MonERC721TestBase} from "../MonERC721TestBase.t.sol";
import {MonERC721} from "../../../src/MonERC721.sol";

/**
 * @title MintWithNativeTokenTest
 * @dev Test the mintWithNativeToken function
 */
contract MintWithNativeTokenTest is MonERC721TestBase {
    event TokenMinted(address indexed to, uint256 indexed tokenId);

    function setUp() public override {
        super.setUp();
    }

    /**
     * @dev Test the mintWithNativeToken function
     * @notice Asserts that the token is minted correctly
     */
    function test_mintWithNativeToken() public {
        uint256 previusCurrentId = monERC721.currentTokenId();
        vm.startPrank(alice);
        monERC721.mintWithNativeToken{value: PRICE_IN_NATIVE_TOKEN}();
        vm.stopPrank();

        assertEq(monERC721.balanceOf(alice), 1);
        assertEq(address(alice).balance, ALICE_NATIVE_BALANCE - PRICE_IN_NATIVE_TOKEN);
        assertEq(monERC721.ownerOf(1), alice);
        assertEq(monERC721.currentTokenId(), previusCurrentId + 1);
    }

    /**
     * @dev Test the mintWithNativeToken function
     * @notice Asserts that the token is minted correctly and sends back excess native tokens
     */
    function test_mintWithNativeToken_sendsBackExcess() public {
        vm.startPrank(alice);
        monERC721.mintWithNativeToken{value: PRICE_IN_NATIVE_TOKEN + 1 ether}();
        vm.stopPrank();

        assertEq(monERC721.balanceOf(alice), 1);
        assertEq(address(alice).balance, ALICE_NATIVE_BALANCE - PRICE_IN_NATIVE_TOKEN);
        assertEq(monERC721.ownerOf(1), alice);
    }

    /**
     * @dev Test the mintWithNativeToken function
     * @notice Asserts that it reverts if the value is less than the price
     */
    function test_mintWithNativeToken_revertsIfValueIsLessThanPrice() public {
        vm.expectRevert(MonERC721.MonERC721__NotEnoughNativeTokens.selector);
        vm.startPrank(alice);
        monERC721.mintWithNativeToken{value: PRICE_IN_NATIVE_TOKEN - 1}();
        vm.stopPrank();
    }

    /**
     * @dev Test the mintWithNativeToken function
     * @notice Asserts that it reverts if the max supply is reached
     */
    function test_mintWithNativeToken_revertsIfMaxSupplyIsReached() public {
        vm.startPrank(alice);
        for (uint256 i = 0; i < MAX_SUPPLY; i++) {
            monERC721.mintWithNativeToken{value: PRICE_IN_NATIVE_TOKEN}();
        }
        vm.expectRevert(MonERC721.MonERC721__MaxSupplyReached.selector);
        monERC721.mintWithNativeToken{value: PRICE_IN_NATIVE_TOKEN}();
        vm.stopPrank();
    }

    /**
     * @dev Test the mintWithNativeToken function
     * @notice Asserts that it reverts if the receiver fails to receive
     */
    function test_mintWithNativeToken_revertsIfReceiverFailsToReceive() public {
        vm.expectRevert(MonERC721.MonERC721__NativeTransferFailed.selector);
        vm.startPrank(alice);
        revertingContract.mint();
        vm.stopPrank();
    }

    /**
     * @dev Test the mintWithNativeToken function
     * @notice Asserts that the token is minted correctly emitting an event
     */
    function test_mintWithNativeToken_emitsAnEvent() public {
        vm.expectEmit(true, true, false, false);
        emit TokenMinted(alice, 1);
        vm.startPrank(alice);
        monERC721.mintWithNativeToken{value: PRICE_IN_NATIVE_TOKEN}();
        vm.stopPrank();
    }
}
