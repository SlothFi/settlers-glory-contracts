// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {MonERC721TestBase} from "../MonERC721TestBase.t.sol";
import {MonERC721} from "../../../src/MonERC721.sol";

/**
 * @title WithdrawNativeTokensTest
 * @dev Test the withdrawNativeTokens function
 */
contract WithdrawNativeTokensTest is MonERC721TestBase {
    event NativeTokensWithdrawn(address indexed to, uint256 indexed amount);

    uint256 public constant EXPECTED_NATIVE_BALANCE = PRICE_IN_NATIVE_TOKEN;

    function setUp() public override {
        super.setUp();
    }

    /**
     * @dev Test the withdrawNativeTokens function
     * @notice Asserts that the native tokens are withdrawn correctly with the specified amount
     */
    function test_withdrawNativeTokensWithSpecifiedAmount() public {
        _buyNft();
        vm.startPrank(owner);
        monERC721.withdrawNativeTokens(EXPECTED_NATIVE_BALANCE / 2);
        vm.stopPrank();

        assertEq(address(monERC721).balance, EXPECTED_NATIVE_BALANCE / 2);
        assertEq(address(fundsWallet).balance, EXPECTED_NATIVE_BALANCE / 2);
    }

    /**
     * @dev Test the withdrawNativeTokens function
     * @notice Asserts that the native tokens are withdrawn correctly with the full balance
     */
    function test_withdrawNativeTokensWithAllBalance() public {
        _buyNft();
        vm.startPrank(owner);
        monERC721.withdrawNativeTokens(type(uint256).max);
        vm.stopPrank();

        assertEq(address(monERC721).balance, 0);
        assertEq(address(fundsWallet).balance, EXPECTED_NATIVE_BALANCE);
    }

    /**
     * @dev Test the withdrawNativeTokens function
     * @notice Asserts that it reverts if the caller is not the owner
     */
    function test_withdrawNativeTokens_revertsIfNotOwner() public {
        vm.expectRevert();
        vm.startPrank(alice);
        monERC721.withdrawNativeTokens(EXPECTED_NATIVE_BALANCE);
        vm.stopPrank();
    }

    /**
     * @dev Test the withdrawNativeTokens function
     * @notice Asserts that it reverts if the amount is greater than the balance
     */
    function test_withdrawNativeTokens_revertsIfAmountIsGreaterThanBalance() public {
        _buyNft();
        vm.expectRevert(MonERC721.MonERC721__NotEnoughNativeTokens.selector);
        vm.startPrank(owner);
        monERC721.withdrawNativeTokens(EXPECTED_NATIVE_BALANCE + 1);
        vm.stopPrank();
    }

    /**
     * @dev Test the withdrawNativeTokens function
     * @notice Asserts that it reverts if the amount is zero
     */
    function test_withdrawNativeTokens_revertsIfAmountIsZero() public {
        _buyNft();
        vm.expectRevert(MonERC721.MonERC721__NoZeroAmount.selector);
        vm.startPrank(owner);
        monERC721.withdrawNativeTokens(0);
        vm.stopPrank();
    }

    /**
     * @dev Test the withdrawNativeTokens function
     * @notice Asserts that it reverts if the receiver fails to receive the native tokens
     */
    function test_withdrawNativeTokens_revertsIfReceiverFailsToReceive() public {
        vm.startPrank(owner);
        monERC721.setFundsWallet(address(revertingContract));
        vm.stopPrank();
        _buyNft();
        vm.expectRevert(MonERC721.MonERC721__NativeTransferFailed.selector);
        vm.startPrank(owner);
        monERC721.withdrawNativeTokens(EXPECTED_NATIVE_BALANCE);
        vm.stopPrank();
    }

    /**
     * @dev Test the withdrawNativeTokens function
     * @notice Asserts that it emits an event
     */
    function test_withdrawNativeTokens_emitsAnEvent() public {
        _buyNft();
        vm.expectEmit(true, true, false, false);
        emit NativeTokensWithdrawn(fundsWallet, EXPECTED_NATIVE_BALANCE);
        vm.startPrank(owner);
        monERC721.withdrawNativeTokens(EXPECTED_NATIVE_BALANCE);
        vm.stopPrank();
    }

    /**
     * @dev Buy an NFT
     * @notice Helper function to buy an NFT
     */
    function _buyNft() internal {
        vm.startPrank(alice);
        monERC721.mintWithNativeToken{value: PRICE_IN_NATIVE_TOKEN}();
        vm.stopPrank();
        assertEq(address(monERC721).balance, EXPECTED_NATIVE_BALANCE);
    }
}
