// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {MonStakingTestBase} from "../MonStakingTestBase.t.sol";
import {MockMonsterToken} from "../../../src/mocks/MockMonsterToken.sol";
import {MonStaking} from "../../../src/MonStaking.sol";
import {LiquidStakedMonster} from "../../../src/LiquidStakedMonster.sol";
import {IMonStakingErrors} from "../../../src/interfaces/errors/IMonStakingErrors.sol";

/**
 * @title UnstakingTests
 * @dev Tests for unstaking NFTs in MonStaking
 */
contract UnstakingTests is MonStakingTestBase {

    function setUp() public override {
        super.setUp();
    }

    // tests for unstakeTokens function

    function testUnstakeTokensSuccess() public {
        uint256 amount = 1000 * 10 ** 18;

        vm.startPrank(user);
        _stakeTokensNotPremium(amount);

        // Unstake tokens
        monStaking.unstakeTokens(amount);
        vm.stopPrank();

        
        assertEq(monStaking.s_userStakedTokenAmount(user), 0);
        assertEq(liquidStakedMonster.balanceOf(user), 0);
    }

    function testUnstakeTokensZeroAmount() public {
        uint256 amount = 0;

        vm.startPrank(user);
        vm.expectRevert(IMonStakingErrors.MonStaking__ZeroAmount.selector);
        monStaking.unstakeTokens(amount);
        vm.stopPrank();
    }

    function testUnstakeTokensNotEnoughTokens() public {
        uint256 amount = monStaking.s_userStakedTokenAmount(user) + 1;

        vm.startPrank(user);

        // Attempt to unstake more tokens than staked
        vm.expectRevert(IMonStakingErrors.MonStaking__NotEnoughMonsterTokens.selector);
        monStaking.unstakeTokens(amount);
        vm.stopPrank();
    }

    function testUnstakeTokensCannotTotallyUnstake() public {
        uint256 amount = 1000 * 10 ** 18;

        vm.startPrank(user);

        _stakeTokensPremium(amount);

        
        vm.expectRevert(IMonStakingErrors.MonStaking__CannotTotallyUnstake.selector);
        monStaking.unstakeTokens(amount);
        vm.stopPrank();
    }

    function testUnstakeTokensClearUserTimeInfo() public {
        uint256 amount = 1000 * 10 ** 18;

        vm.startPrank(user);

        _stakeTokensNotPremium(amount);

        // Unstake tokens
        monStaking.unstakeTokens(amount);
        vm.stopPrank();

        
        assertEq(monStaking.s_userLastUpdatedTimestamp(user), 0);
    }

    function testUnstakeTokensNotClearUserTimeInfo() public {
        uint256 amount = 1000 * 10 ** 18 + 1;

        vm.startPrank(user);

        _stakeTokensNotPremium(amount);

        // Unstake tokens
        monStaking.unstakeTokens(amount - 1);
        vm.stopPrank();

        
        assertEq(monStaking.s_userLastUpdatedTimestamp(user), block.timestamp);
    }

    //tests for unstakeNft function

    function testUnstakeNftSuccess() public {
        uint256 tokenId = 1;

        vm.startPrank(user);

        
        _stakeNftNotPremium(tokenId);

        
        monStaking.unstakeNft(tokenId);
        vm.stopPrank();

        
        assertEq(monStaking.s_userNftAmount(user), 0);
        assertEq(monStaking.s_nftOwner(tokenId), address(0));
        assertEq(monERC721.ownerOf(tokenId), user);
    }

    function testUnstakeNftInvalidTokenId() public {
        uint256 tokenId = 0;

        vm.startPrank(user);
        vm.expectRevert(IMonStakingErrors.MonStaking__InvalidTokenId.selector);
        monStaking.unstakeNft(tokenId);
        vm.stopPrank();
    }

    function testUnstakeNftBiggerMaxSupply() public {
        uint256 tokenId = maxSupply + 1;

        vm.startPrank(user);
        vm.expectRevert(IMonStakingErrors.MonStaking__InvalidTokenId.selector);
        monStaking.unstakeNft(tokenId);
        vm.stopPrank();
    }

    function testUnstakeNftNoNftBalance() public {
        uint256 tokenId = 1;

        assertEq(monStaking.s_userNftAmount(user), 0);

        vm.startPrank(user);
        vm.expectRevert(IMonStakingErrors.MonStaking__ZeroAmount.selector);
        monStaking.unstakeNft(tokenId);
        vm.stopPrank();
    }

    function testUnstakeNftCannotTotallyUnstake() public {
        uint256 tokenId = 1;

        vm.startPrank(user);

        
        _stakeNftPremium(tokenId);

        
        vm.expectRevert(IMonStakingErrors.MonStaking__CannotTotallyUnstake.selector);
        monStaking.unstakeNft(tokenId);
        vm.stopPrank();
    }

    function testUnstakeNftNotNftOwner() public {
        uint256 tokenId = 1;
        address notOwner = makeAddr("notOwner");

        vm.startPrank(user);

        
        _stakeNftNotPremium(tokenId);

        
        vm.expectRevert(IMonStakingErrors.MonStaking__NotNftOwner.selector);
        monStaking.unstakeNft(tokenId + 1);
    }

    function testUnstakeNftClearUserTimeInfo() public {
        uint256 tokenId = 1;
        vm.startPrank(user);

        
        _stakeNftNotPremium(tokenId);

        
        monStaking.unstakeNft(tokenId);
        vm.stopPrank();

        
        assertEq(monStaking.s_userLastUpdatedTimestamp(user), 0);
    }

    function testUnstakeNftNotClearUserTimeInfo() public {
        uint256 tokenId = 1;

        vm.startPrank(user);

        
        _stakeNftNotPremium(tokenId);

        _stakeNftNotPremium(tokenId + 1);

        
        monStaking.unstakeNft(tokenId);
        vm.stopPrank();

        
        assertEq(monStaking.s_userLastUpdatedTimestamp(user), block.timestamp);
    }

    // tests for batchUnstakeNft function

    function testBatchUnstakeNftSuccess() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
    
        vm.startPrank(user);
    
        
        _stakeNftNotPremium(tokenIds[0]);
        _stakeNftNotPremium(tokenIds[1]);
    
        
        monStaking.batchUnstakeNft(tokenIds);
        vm.stopPrank();
    
        
        assertEq(monStaking.s_userNftAmount(user), 0);
        assertEq(monStaking.s_nftOwner(tokenIds[0]), address(0));
        assertEq(monStaking.s_nftOwner(tokenIds[1]), address(0));
        assertEq(monERC721.ownerOf(tokenIds[0]), user);
        assertEq(monERC721.ownerOf(tokenIds[1]), user);
    }
    
    function testBatchUnstakeNftInvalidIdArrayLength() public {
        uint256[] memory tokenIds = new uint256[](0);
    
        vm.startPrank(user);
        vm.expectRevert(IMonStakingErrors.MonStaking__InvalidIdArrayLength.selector);
        monStaking.batchUnstakeNft(tokenIds);
    }
    
    function testBatchUnstakeNftExceedsMaxBatchWithdraw() public {
        uint256 MAX_BATCH_NFT_WITHDRAW = monStaking.MAX_BATCH_NFT_WITHDRAW();
        uint256[] memory tokenIds = new uint256[](MAX_BATCH_NFT_WITHDRAW + 1);
    
        vm.startPrank(user);
        vm.expectRevert(IMonStakingErrors.MonStaking__InvalidIdArrayLength.selector);
        monStaking.batchUnstakeNft(tokenIds);
        vm.stopPrank();
    }
    
    function testBatchUnstakeNftCannotTotallyUnstake() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
    
        vm.startPrank(user);
    
        
        _stakeNftPremium(tokenIds[0]);
    
        
        vm.expectRevert(IMonStakingErrors.MonStaking__CannotTotallyUnstake.selector);
        monStaking.batchUnstakeNft(tokenIds);
        vm.stopPrank();
    }
    
    function testBatchUnstakeNftNotNftOwner() public {
        uint256 tokenId = 1;
        
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId + 1;
    
        vm.startPrank(user);
    
        
        _stakeNftNotPremium(tokenId);
    
        
        vm.expectRevert(IMonStakingErrors.MonStaking__NotNftOwner.selector);
        monStaking.batchUnstakeNft(tokenIds);
        vm.stopPrank();
    }
    
    function testBatchUnstakeNftClearUserTimeInfo() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
    
        vm.startPrank(user);
    
        
        _stakeNftNotPremium(tokenIds[0]);
    
        
        monStaking.batchUnstakeNft(tokenIds);
        vm.stopPrank();
    
        
        assertEq(monStaking.s_userLastUpdatedTimestamp(user), 0);
    }
    
    function testBatchUnstakeNftNotClearUserTimeInfo() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
    
        vm.startPrank(user);
    
        
        _stakeNftNotPremium(tokenIds[0]);
        _stakeNftNotPremium(tokenIds[0] + 1);
    
        
        monStaking.batchUnstakeNft(tokenIds);
        vm.stopPrank();
    
        
        assertEq(monStaking.s_userLastUpdatedTimestamp(user), block.timestamp);
    }

    // tests for requireUnstakeAll function 

    function testRequireUnstakeAllSuccess() public {
        uint256 tokenAmount = 1000 * 10 ** 18;
        uint256 tokenId = 1;
    
        vm.startPrank(user);
    
        _stakeTokensPremium(tokenAmount);
        _stakeNftPremium(tokenId);
        
        monStaking.requireUnstakeAll();
        vm.stopPrank();
    
        assertEq(monStaking.s_userStakedTokenAmount(user), 0);
        assertEq(monStaking.s_userNftAmount(user), 0);
        assertEq(monStaking.s_userLastUpdatedTimestamp(user), 0);
        assertEq(monStaking.s_isUserPremium(user), false);
    }
    
    function testRequireUnstakeAllNotPremium() public {
        vm.startPrank(user);
    
        _stakeTokensNotPremium(1000 * 10 ** 18);

        // Attempt to require total unstake while not being premium
        vm.expectRevert(IMonStakingErrors.MonStaking__UserNotPremium.selector);
        monStaking.requireUnstakeAll();
        vm.stopPrank();
    }
    
    function testRequireUnstakeAllUpdateExistingRequest() public {
        uint256 tokenAmount = 1000 * 10 ** 18;
        uint256 tokenId = 1;
    
        vm.startPrank(user);
    
        
        _stakeTokensPremium(tokenAmount);
        _stakeNftPremium(tokenId);
    
        
        monStaking.requireUnstakeAll();
    
        // Stake more tokens and NFT
        _stakeTokensPremium(tokenAmount);
        _stakeNftPremium(tokenId + 1);
    
        
        monStaking.requireUnstakeAll();
        vm.stopPrank();
    
        
        assertEq(monStaking.s_userStakedTokenAmount(user), 0);
        assertEq(monStaking.s_userNftAmount(user), 0);
        assertEq(monStaking.s_userLastUpdatedTimestamp(user), 0);
        assertEq(monStaking.s_isUserPremium(user), false);
    }
    
    function testRequireUnstakeAllBurnTokens() public {
        uint256 tokenAmount = 1000 * 10 ** 18;
        uint256 tokenId = 1;
    
        vm.startPrank(user);
    
        
        _stakeTokensPremium(tokenAmount);
        _stakeNftPremium(tokenId);
    
        
        monStaking.requireUnstakeAll();
        vm.stopPrank();
    
        // Verify tokens are burned
        assertEq(liquidStakedMonster.balanceOf(user), 0);
    }
    
    function testRequireUnstakeAllUpdateOtherChains() public {
        uint256 tokenAmount = 1000 * 10 ** 18;
        uint256 tokenId = 1;
    
        vm.startPrank(user);
    
        
        _stakeTokensPremium(tokenAmount);
        _stakeNftPremium(tokenId);
    
        
        monStaking.requireUnstakeAll();
        vm.stopPrank();
    }

    // tests for claimUnstakedAssets function

    function testClaimUnstakedAssetsSuccess() public {
        uint256 tokenAmount = 1000 * 10 ** 18;
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
    
        vm.startPrank(user);
    
        _stakeTokensPremium(tokenAmount);
        _stakeNftPremium(tokenIds[0]);
        _stakeNftPremium(tokenIds[1]);
    
        monStaking.requireUnstakeAll();
        
        vm.warp(block.timestamp + monStaking.TIME_LOCK_DURATION() + 1);
        
        monStaking.claimUnstakedAssets(tokenIds);
        vm.stopPrank();
    
        assertEq(monERC721.ownerOf(tokenIds[0]), user);
        assertEq(monERC721.ownerOf(tokenIds[1]), user);
        // assertEq(monsterToken.balanceOf(user), tokenAmount - tokenIds.length * priceInMonsterToken);
    }
    
    function testClaimUnstakedAssetsTimelockNotPassed() public {
        uint256 tokenAmount = 1000 * 10 ** 18;
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
    
        vm.startPrank(user);
    
        _stakeTokensPremium(tokenAmount);
        _stakeNftPremium(tokenIds[0]);
        _stakeNftPremium(tokenIds[1]);
    
        monStaking.requireUnstakeAll();
    
        vm.expectRevert(IMonStakingErrors.MonStaking__TimelockNotPassed.selector);
        monStaking.claimUnstakedAssets(tokenIds);
        vm.stopPrank();
    }
    
    function testClaimUnstakedAssetsTokenIdArrayTooLong() public {
        uint256 tokenAmount = 1000 * 10 ** 18;
        uint256 MAX_BATCH_NFT_WITHDRAW = monStaking.MAX_BATCH_NFT_WITHDRAW();
        uint256[] memory tokenIds = new uint256[](MAX_BATCH_NFT_WITHDRAW + 1);
    
        vm.startPrank(user);
    
        
        _stakeTokensPremium(tokenAmount);
        for (uint256 i = 0; i < MAX_BATCH_NFT_WITHDRAW + 1; i++) {
            _stakeNftPremium(i + 1);
            tokenIds[i] = i + 1;
        }
    
        
        monStaking.requireUnstakeAll();
    
        
        vm.warp(block.timestamp + monStaking.TIME_LOCK_DURATION() + 1);
    
        
        vm.expectRevert(IMonStakingErrors.MonStaking__TokenIdArrayTooLong.selector);
        monStaking.claimUnstakedAssets(tokenIds);
        vm.stopPrank();
    }
    
    function testClaimUnstakedAssetsNotNftOwner() public {
        uint256 tokenAmount = 1000 * 10 ** 18;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
    
        vm.startPrank(user);
    
        
        _stakeTokensPremium(tokenAmount);
        _stakeNftPremium(tokenIds[0]);
    
        
        monStaking.requireUnstakeAll();
    
        
        vm.warp(block.timestamp + monStaking.TIME_LOCK_DURATION() + 1);
    
        address notOwner = makeAddr("notOwner");
        vm.startPrank(notOwner);
        vm.expectRevert(IMonStakingErrors.MonStaking__NotNftOwner.selector);
        monStaking.claimUnstakedAssets(tokenIds);
        vm.stopPrank();
    }

    // Helper functions

    function _mintNft(uint amount) internal {
        monsterToken.approve(address(monERC721), amount);
        monERC721.mintWithMonsterToken();
    }

    function _approveNft(uint256 tokenId) internal {
        monERC721.approve(address(monStaking), tokenId);
    }

    function _stakeTokensPremium(uint256 amount) internal {
        monsterToken.approve(address(monStaking), amount);
        monStaking.stakeTokens(amount);
    }

    function _stakeTokensNotPremium(uint256 amount) internal {
        vm.warp(monStaking.i_endPremiumTimestamp() + 1);
        monsterToken.approve(address(monStaking), amount);
        monStaking.stakeTokens(amount);
    }

    function _stakeNftPremium(uint256 tokenId) internal {
        _mintNft(priceInMonsterToken);
        _approveNft(tokenId);
        monStaking.stakeNft(tokenId);
    }

    function _stakeNftNotPremium(uint256 tokenId) internal {
        vm.warp(monStaking.i_endPremiumTimestamp() + 1);
        _mintNft(priceInMonsterToken);
        _approveNft(tokenId);
        monStaking.stakeNft(tokenId);
    }
}