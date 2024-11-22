// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {MonERC721TestBase} from "../MonERC721TestBase.t.sol";
import {MonERC721} from "../../../src/MonERC721.sol";

/**
 * @title MintWithMonsterTokenTest
 * @dev Test the mintWithMonsterToken function
 */
contract MintWithMonsterTokenTest is MonERC721TestBase {
    event TokenMinted(address indexed to, uint256 indexed tokenId);

    function setUp() public override {
        super.setUp();
    }

    /**
     * @dev Test the mintWithMonsterToken function
     * @notice Asserts that the token is minted correctly with monster token
     */
    function test_mintWithMonsterToken() public {
        uint256 previusCurrentId = monERC721.currentTokenId();
        vm.startPrank(alice);
        monERC721.mintWithMonsterToken();
        vm.stopPrank();

        assertEq(monERC721.balanceOf(alice), 1);
        assertEq(monERC721.ownerOf(1), alice);
        assertEq(monERC721.currentTokenId(), previusCurrentId + 1);
        assertEq(monsterToken.balanceOf(address(monERC721)), PRICE_IN_MONSTER_TOKEN);
        assertEq(monsterToken.balanceOf(alice), ALICE_MONSTER_BALANCE - PRICE_IN_MONSTER_TOKEN);
    }

    /**
     * @dev Test the mintWithMonsterToken function
     * @notice Asserts that it revert if the max supply is reached
     */
    function test_mintWithMonsterToken_revertsIfMaxSupplyIsReached() public {
        vm.startPrank(alice);
        for (uint256 i = 0; i < MAX_SUPPLY; i++) {
            monERC721.mintWithMonsterToken();
        }
        vm.expectRevert(MonERC721.MonERC721__MaxSupplyReached.selector);
        monERC721.mintWithMonsterToken();
        vm.stopPrank();
    }

    /**
     * @dev Test the mintWithMonsterToken function
     * @notice Asserts that it mints correctly emitting an event
     */
    function test_mintWithMonsterToken_emitsAnEvent() public {
        vm.expectEmit(true, true, false, false);
        emit TokenMinted(alice, 1);
        vm.startPrank(alice);
        monERC721.mintWithMonsterToken();
        vm.stopPrank();
    }
}
