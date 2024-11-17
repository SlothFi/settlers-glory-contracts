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

    // tests for stakeTokens function

    function testStakeTokensSuccess() public {
        uint256 amount = 1000 * 10 ** 18;

        
        vm.startPrank(user);
        monsterToken.approve(address(monStaking), amount);

        
        monStaking.stakeTokens(amount);
        vm.stopPrank();

        
        assertEq(monStaking.s_userStakedTokenAmount(user), amount);
        assertEq(monStaking.s_userPoints(user), 0); 
        assertEq(monsterToken.balanceOf(address(monStaking)), amount);
        assertEq(liquidStakedMonster.balanceOf(user), amount);
    }

    function testStakeTokensZeroAmount() public {
        uint256 amount = 0;

        vm.startPrank(user);
        vm.expectRevert(IMonStakingErrors.MonStaking__ZeroAmount.selector);
        monStaking.stakeTokens(amount);
        vm.stopPrank();
    }

    function testStakeTokensPremium() public {
        uint256 amount = 1000 * 10 ** 18;

        
        monsterToken.transfer(user, amount);
        vm.startPrank(user);
        monsterToken.approve(address(monStaking), amount);

        
        monStaking.stakeTokens(amount);
        vm.stopPrank();

        
        assertEq(monStaking.s_isUserPremium(user), true);
        assertEq(monStaking.s_userStakedTokenAmount(user), amount);
        assertEq(monsterToken.balanceOf(address(monStaking)), amount);
        assertEq(liquidStakedMonster.balanceOf(user), amount);
    }

    function testStakeTokenNotPremium() public {
        uint256 amount = 1000 * 10 ** 18;

        
        monsterToken.transfer(user, amount);
        vm.startPrank(user);
        monsterToken.approve(address(monStaking), amount);

         
        vm.warp(monStaking.i_endPremiumTimestamp() + 1);
        monStaking.stakeTokens(amount);
        vm.stopPrank();

        
        assertEq(monStaking.s_isUserPremium(user), false);
    }

    // tests for stakeNft function

    function testStakeNftSuccess() public {
        uint256 tokenId = 1;
        uint256 amount = priceInMonsterToken;

        
        vm.startPrank(user);
        monsterToken.approve(address(monERC721), amount);
        monERC721.mintWithMonsterToken();
        monERC721.approve(address(monStaking), tokenId);

        // Stake NFT
        monStaking.stakeNft(tokenId);
        vm.stopPrank();

        
        assertEq(monStaking.s_userNftAmount(user), 1);
        assertEq(monStaking.s_nftOwner(tokenId), user);
        assertEq(monERC721.ownerOf(tokenId), address(monStaking));
    }

    function testStakeNftInvalidTokenId() public {
        uint256 tokenId = 0;

        vm.startPrank(user);
        vm.expectRevert(IMonStakingErrors.MonStaking__InvalidTokenId.selector);
        monStaking.stakeNft(tokenId);
    }

    function testStakeNftBiggerMaxSupply() public {
        uint256 tokenId = maxSupply + 1;

        vm.startPrank(user);
        vm.expectRevert(IMonStakingErrors.MonStaking__InvalidTokenId.selector);
        monStaking.stakeNft(tokenId);
    }

    function testStakeNftPremium() public {
        uint256 tokenId = 1;
        uint256 amount = priceInMonsterToken;

        
        vm.startPrank(user);
        monsterToken.approve(address(monERC721), amount);
        monERC721.mintWithMonsterToken();
        monERC721.approve(address(monStaking), tokenId);

        monStaking.stakeNft(tokenId);
        vm.stopPrank();

        
        assertEq(monStaking.s_isUserPremium(user), true);
        assertEq(monStaking.s_userNftAmount(user), 1);
        assertEq(monStaking.s_nftOwner(tokenId), user);
        assertEq(monERC721.ownerOf(tokenId), address(monStaking));
    }

    function testStakeNftNotPremium() public {
        uint256 tokenId = 1;
        uint256 amount = priceInMonsterToken;

        
        vm.startPrank(user);
        monsterToken.approve(address(monERC721), amount);
        monERC721.mintWithMonsterToken();
        monERC721.approve(address(monStaking), tokenId);

        
        vm.warp(monStaking.i_endPremiumTimestamp() + 1);
        monStaking.stakeNft(tokenId);
        vm.stopPrank();

        
        assertEq(monStaking.s_isUserPremium(user), false);
    }

    // tests for updateStakingBalance function

    function testUpdateStakingBalanceSuccess() public {
        uint256 amount = 1000 * 10 ** 18;
        address from = user;
        address to = makeAddr("to");
        
        monsterToken.transfer(from, amount);
        vm.startPrank(from);
        monsterToken.approve(address(monStaking), amount);
        
        monStaking.stakeTokens(amount);
        vm.stopPrank();

        vm.startPrank(address(liquidStakedMonster));
        monStaking.updateStakingBalance(from, to, amount);
        vm.stopPrank();

        
        assertEq(monStaking.s_userStakedTokenAmount(from), 0);
        assertEq(monStaking.s_userStakedTokenAmount(to), amount);
        assertEq(monStaking.s_userPoints(from), 0); 
        assertEq(monStaking.s_userPoints(to), 0); 
        assertEq(monsterToken.balanceOf(address(monStaking)), amount);
        // assertEq(liquidStakedMonster.balanceOf(from), 0);
        // assertEq(liquidStakedMonster.balanceOf(to), amount);
    }

    function testUpdateStakingBalanceNotLSMCaller() public {
        uint256 amount = 1000 * 10 ** 18;
        address from = user;
        address to = makeAddr("to");

        monsterToken.transfer(from, amount);
        vm.startPrank(from);
        monsterToken.approve(address(monStaking), amount);

        monStaking.stakeTokens(amount);
        vm.stopPrank();

        vm.startPrank(address(monStaking));
        vm.expectRevert(IMonStakingErrors.MonStaking__NotLSMContract.selector);
        monStaking.updateStakingBalance(from, to, amount);
        vm.stopPrank();
    }

    function testUpdateStakingBalanceZeroAddress() public {
        uint256 amount = 1000 * 10 ** 18;
        address from = address(0);
        address to = user;

        vm.startPrank(address(liquidStakedMonster));
        vm.expectRevert(IMonStakingErrors.MonStaking__ZeroAddress.selector);
        monStaking.updateStakingBalance(from, to, amount);
        vm.stopPrank();
    }

    function testUpdateStakingBalanceZeroToAddress() public {
        uint256 amount = 1000 * 10 ** 18;
        address from = user;
        address to = address(0);

        vm.startPrank(address(liquidStakedMonster));
        vm.expectRevert(IMonStakingErrors.MonStaking__ZeroAddress.selector);
        monStaking.updateStakingBalance(from, to, amount);
        vm.stopPrank();
    }

    function testUpdateStakingBalanceZeroAmount() public {
        uint256 amount = 0;
        address from = user;
        address to = makeAddr("to");

        vm.startPrank(address(liquidStakedMonster));
        vm.expectRevert(IMonStakingErrors.MonStaking__ZeroAmount.selector);
        monStaking.updateStakingBalance(from, to, amount);
        vm.stopPrank();
    }

    function testUpdateStakingBalanceClearUserTimeInfo() public {
        uint256 amount = 1000 * 10 ** 18;
        address from = user;
        address to = makeAddr("to");

        monsterToken.transfer(from, amount);
        vm.startPrank(from);
        monsterToken.approve(address(monStaking), amount);

        monStaking.stakeTokens(amount);
        vm.stopPrank();

        vm.startPrank(address(liquidStakedMonster));
        monStaking.updateStakingBalance(from, to, amount);
        vm.stopPrank();

        assertEq(monStaking.s_userLastUpdatedTimestamp(from), 0);
    }

    function testUpdateStakingBalanceNotClearUserTimeInfo() public {
        uint256 amount = 1000 * 10 ** 18;
        address from = user;
        address to = makeAddr("to");

        monsterToken.transfer(from, amount);
        vm.startPrank(from);
        monsterToken.approve(address(monStaking), amount);

        monStaking.stakeTokens(amount);
        vm.stopPrank();

        vm.startPrank(address(liquidStakedMonster));
        monStaking.updateStakingBalance(from, to, amount - 1);
        vm.stopPrank();

        assertEq(monStaking.s_userLastUpdatedTimestamp(from), block.timestamp);
    }

}