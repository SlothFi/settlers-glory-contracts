// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {MonERC721TestBase} from "../MonERC721TestBase.t.sol";
import {MonERC721} from "../../../src/MonERC721.sol";

/**
 * @title WithdrawMonsterTokensTest
 * @dev Test the withdrawMonsterTokens function
 */
contract WithdrawMonsterTokensTest is MonERC721TestBase {
    event MonsterTokensWithdrawn(address indexed to, uint256 indexed amount);

    uint256 public constant EXPECTED_MONSTER_BALANCE = PRICE_IN_MONSTER_TOKEN;

    function setUp() public override {
        super.setUp();
    }

    /**
     * @dev Test the withdrawMonsterTokens function
     * @notice Asserts that the monster tokens are withdrawn correctly with the specified amount
     */
    function test_withdrawMonsterTokensWithSpecifiedAmount() public {
        _buyNft();
        vm.startPrank(owner);
        monERC721.withdrawMonsterTokens(EXPECTED_MONSTER_BALANCE / 2);
        vm.stopPrank();

        assertEq(monsterToken.balanceOf(address(monERC721)), EXPECTED_MONSTER_BALANCE / 2);
        assertEq(monsterToken.balanceOf(fundsWallet), EXPECTED_MONSTER_BALANCE / 2);
    }

    /**
     * @dev Test the withdrawMonsterTokens function
     * @notice Asserts that the monster tokens are withdrawn correctly with the full balance
     */
    function test_withdrawMonsterTokensWithAllBalance() public {
        _buyNft();
        vm.startPrank(owner);
        monERC721.withdrawMonsterTokens(type(uint256).max);
        vm.stopPrank();

        assertEq(monsterToken.balanceOf(address(monERC721)), 0);
        assertEq(monsterToken.balanceOf(fundsWallet), EXPECTED_MONSTER_BALANCE);
    }

    /**
     * @dev Test the withdrawMonsterTokens function
     * @notice Asserts that it reverts if the caller is not the owner
     */
    function test_withdrawMonsterTokens_revertsIfNotOwner() public {
        vm.expectRevert();
        vm.startPrank(alice);
        monERC721.withdrawMonsterTokens(EXPECTED_MONSTER_BALANCE);
        vm.stopPrank();
    }

    /**
     * @dev Test the withdrawMonsterTokens function
     * @notice Asserts that it reverts if the amount is greater than the balance
     */
    function test_withdrawMonsterTokens_revertsIfAmountIsGreaterThanBalance() public {
        _buyNft();
        vm.expectRevert(MonERC721.MonERC721__NotEnoughMonterTokens.selector);
        vm.startPrank(owner);
        monERC721.withdrawMonsterTokens(EXPECTED_MONSTER_BALANCE + 1);
        vm.stopPrank();
    }

    /**
     * @dev Test the withdrawMonsterTokens function
     * @notice Asserts that it reverts if the amount is zero
     */
    function test_withdrawMonsterTokens_revertsIfAmountIsZero() public {
        _buyNft();
        vm.expectRevert(MonERC721.MonERC721__NoZeroAmount.selector);
        vm.startPrank(owner);
        monERC721.withdrawMonsterTokens(0);
        vm.stopPrank();
    }

    /**
     * @dev Test the withdrawMonsterTokens function
     * @notice Asserts that it emits an event
     */
    function test_withdrawMonsterTokens_emitsAnEvent() public {
        _buyNft();
        vm.expectEmit(true, true, false, false);
        emit MonsterTokensWithdrawn(fundsWallet, EXPECTED_MONSTER_BALANCE);
        vm.startPrank(owner);
        monERC721.withdrawMonsterTokens(EXPECTED_MONSTER_BALANCE);
        vm.stopPrank();
    }

    /**
     * @dev Buy an NFT
     * @notice It is an helper function to buy an NFT
     */
    function _buyNft() internal {
        vm.startPrank(alice);
        monERC721.mintWithMonsterToken();
        vm.stopPrank();
        assertEq(monsterToken.balanceOf(address(monERC721)), EXPECTED_MONSTER_BALANCE);
    }
}
