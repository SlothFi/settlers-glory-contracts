// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {MonStakingTestBase} from "../MonStakingTestBase.t.sol";
import {MockMonsterToken} from "../../../src/mocks/MockMonsterToken.sol";
import {MonStaking} from "../../../src/MonStaking.sol";
import {LiquidStakedMonster} from "../../../src/LiquidStakedMonster.sol";
import {IMonStakingErrors} from "../../../src/interfaces/errors/IMonStakingErrors.sol";

/**
 * @title StakingTests
 * @dev Tests for staking tokens and NFTs in MonStaking
 */
contract StakingTests is MonStakingTestBase {

    function setUp() public override {
        super.setUp();
    }

    function testStakeTokensSuccess() public {
        uint256 amount = 1000 * 10 ** 18;

        // Transfer tokens to user and approve MonStaking contract
        monsterToken.transfer(user, amount);
        vm.startPrank(user);
        monsterToken.approve(address(monStaking), amount);

        // Stake tokens
        monStaking.stakeTokens{value: 0}(amount);
        vm.stopPrank();

        // Verify balances and state
        assertEq(monStaking.s_userStakedTokenAmount(user), amount);
        assertEq(monStaking.s_userPoints(user), 0); // Points are updated on state change
        assertEq(monsterToken.balanceOf(address(monStaking)), amount);
        assertEq(liquidStakedMonster.balanceOf(user), amount);
    }

    function testStakeTokensZeroAmount() public {
        uint256 amount = 0;

        vm.startPrank(user);
        vm.expectRevert(IMonStakingErrors.MonStaking__ZeroAmount.selector);
        monStaking.stakeTokens{value: 0}(amount);
        vm.stopPrank();
    }

    function testStakeTokensPremium() public {
        uint256 amount = 1000 * 10 ** 18;

        // Transfer tokens to user and approve MonStaking contract
        monsterToken.transfer(user, amount);
        vm.startPrank(user);
        monsterToken.approve(address(monStaking), amount);

        // Stake tokens within premium duration
        vm.warp(monStaking.i_creationTimestamp() + monStaking.i_premiumDuration() - 1);
        monStaking.stakeTokens{value: 0}(amount);
        vm.stopPrank();

        // Verify premium status and balances
        assertEq(monStaking.s_isUserPremium(user), true);
        assertEq(monStaking.s_userStakedTokenAmount(user), amount);
        assertEq(monsterToken.balanceOf(address(monStaking)), amount);
        assertEq(liquidStakedMonster.balanceOf(user), amount);
    }

    function testStakeNftSuccess() public {
        uint256 tokenId = 1;
        uint256 amount = priceInMonsterToken;

        // Mint NFT to user using monster tokens and approve MonStaking contract
        vm.startPrank(user);
        monsterToken.approve(address(monERC721), amount);
        monERC721.mintWithMonsterToken();
        monERC721.approve(address(monStaking), tokenId);

        // Stake NFT
        monStaking.stakeNft{value: 0}(tokenId);
        vm.stopPrank();

        // Verify balances and state
        assertEq(monStaking.s_userNftAmount(user), 1);
        assertEq(monStaking.s_nftOwner(tokenId), user);
        assertEq(monERC721.ownerOf(tokenId), address(monStaking));
    }

    function testStakeNftInvalidTokenId() public {
        uint256 tokenId = 0;

        vm.startPrank(user);
        vm.expectRevert(IMonStakingErrors.MonStaking__InvalidTokenId.selector);
        monStaking.stakeNft{value: 0}(tokenId);
        vm.stopPrank();
    }

    function testStakeNftPremium() public {
        uint256 tokenId = 1;
        uint256 amount = priceInMonsterToken;

        // Mint NFT to user using monster tokens and approve MonStaking contract
        vm.startPrank(user);
        monsterToken.approve(address(monERC721), amount);
        monERC721.mintWithMonsterToken();
        monERC721.approve(address(monStaking), tokenId);

        // Stake NFT within premium duration
        vm.warp(monStaking.i_creationTimestamp() + monStaking.i_premiumDuration() - 1);
        monStaking.stakeNft{value: 0}(tokenId);
        vm.stopPrank();

        // Verify premium status and balances
        assertEq(monStaking.s_isUserPremium(user), true);
        assertEq(monStaking.s_userNftAmount(user), 1);
        assertEq(monStaking.s_nftOwner(tokenId), user);
        assertEq(monERC721.ownerOf(tokenId), address(monStaking));
    }
}