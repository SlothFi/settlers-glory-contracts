// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {MonStakingTestBase} from "../MonStakingTestBase.t.sol";
import {MonStaking} from "../../../src/MonStaking.sol";
import {IMonStakingErrors} from "../../../src/interfaces/errors/IMonStakingErrors.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OwnerTests
 * @dev Tests for functions with onlyOwner modifier in MonStaking
 */
contract OwnerTests is MonStakingTestBase {

    function setUp() public override {
        super.setUp();
    }

    function testProposeNewOwnerSuccess() public {
        address newOwner = makeAddr("newOwner");

        vm.startPrank(owner);
        monStaking.proposeNewOwner(newOwner);
        vm.stopPrank();

        // Verify new proposed owner
        assertEq(monStaking.s_newProposedOwner(), newOwner);
    }

    function testProposeNewOwnerNotOwner() public {
        address newOwner = makeAddr("newOwner");

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector,user));
        monStaking.proposeNewOwner(newOwner);
        vm.stopPrank();
    }

    function testProposeNewOwnerZeroAddress() public {
        address newOwner = address(0);

        vm.startPrank(owner);
        vm.expectRevert(IMonStakingErrors.MonStaking__ZeroAddress.selector);
        monStaking.proposeNewOwner(newOwner);
        vm.stopPrank();
    }

    function testClaimOwnershipSuccess() public {
        address newOwner = makeAddr("newOwner");

        vm.startPrank(owner);
        monStaking.proposeNewOwner(newOwner);
        vm.stopPrank();

        vm.startPrank(newOwner);
        monStaking.claimOwnerhip();
        vm.stopPrank();

        // Verify new owner
        assertEq(monStaking.owner(), newOwner);
    }

    function testClaimOwnershipNotProposedOwner() public {
        address newOwner = makeAddr("newOwner");

        vm.startPrank(owner);
        monStaking.proposeNewOwner(newOwner);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert(IMonStakingErrors.MonStaking__NotProposedOwner.selector);
        monStaking.claimOwnerhip();
        vm.stopPrank();
    }

    function testRemoveSupportedChainNotOwner() public {
        uint32 chainId = 1;

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector,user));
        monStaking.removeSupportedChain(chainId);
        vm.stopPrank();
    }

    function testRemoveSupportedChainZeroChainId() public {
        uint32 chainId = 0;

        vm.startPrank(owner);
        vm.expectRevert(IMonStakingErrors.MonStaking__ZeroChainId.selector);
        monStaking.removeSupportedChain(chainId);
        vm.stopPrank();
    }

    function testRemoveSupportedChainNotSupported() public {
        uint32 chainId = 1;

        vm.startPrank(owner);
        vm.expectRevert(IMonStakingErrors.MonStaking__ChainNotSupported.selector);
        monStaking.removeSupportedChain(chainId);
        vm.stopPrank();
    }

    function testBatchSetPeersSuccess() public {
        uint32[] memory chainIds = new uint32[](2);
        chainIds[0] = 1;
        chainIds[1] = 2;

        bytes32[] memory peers = new bytes32[](2);
        peers[0] = keccak256(abi.encodePacked("peer1"));
        peers[1] = keccak256(abi.encodePacked("peer2"));

        vm.startPrank(owner);
        monStaking.batchSetPeers(chainIds, peers);
        vm.stopPrank();

        // Verify peers are set
        assertEq(monStaking.s_otherChainStakingContract(chainIds[0]), peers[0]);
        assertEq(monStaking.s_otherChainStakingContract(chainIds[1]), peers[1]);
    }

    function testBatchSetPeersNotOwner() public {
        uint32[] memory chainIds = new uint32[](2);
        chainIds[0] = 1;
        chainIds[1] = 2;

        bytes32[] memory peers = new bytes32[](2);
        peers[0] = keccak256(abi.encodePacked("peer1"));
        peers[1] = keccak256(abi.encodePacked("peer2"));

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector,user));
        monStaking.batchSetPeers(chainIds, peers);
        vm.stopPrank();
    }

    function testBatchSetPeersArrayLengthCannotBeZero() public {
        uint32[] memory chainIds = new uint32[](0);
        bytes32[] memory peers = new bytes32[](0);

        vm.startPrank(owner);
        vm.expectRevert(IMonStakingErrors.MonStaking__ArrayLengthCannotBeZero.selector);
        monStaking.batchSetPeers(chainIds, peers);
        vm.stopPrank();
    }

    function testBatchSetPeersSupportedChainLimitReached() public {
        uint32[] memory chainIds = new uint32[](11);
        bytes32[] memory peers = new bytes32[](11);

        for (uint256 i = 0; i < 11; i++) {
            chainIds[i] = uint32(i + 1);
            peers[i] = keccak256(abi.encodePacked("peer", i + 1));
        }

        vm.startPrank(owner);
        vm.expectRevert(IMonStakingErrors.MonStaking__SupportedChainLimitReached.selector);
        monStaking.batchSetPeers(chainIds, peers);
        vm.stopPrank();
    }

    function testBatchSetPeersMismatch() public {
        uint32[] memory chainIds = new uint32[](2);
        chainIds[0] = 1;
        chainIds[1] = 2;

        bytes32[] memory peers = new bytes32[](1);
        peers[0] = keccak256(abi.encodePacked("peer1"));

        vm.startPrank(owner);
        vm.expectRevert(IMonStakingErrors.MonStaking__PeersMismatch.selector);
        monStaking.batchSetPeers(chainIds, peers);
        vm.stopPrank();
    }

    function testSetMultiplierTokenBaseSuccess() public {
        uint256 newValue = 1;
    
        vm.startPrank(owner);
        monStaking.setMultiplier(MonStaking.Multipliers.TOKEN_BASE, newValue);
        vm.stopPrank();
    
        // Verify the new value is set
        assertEq(monStaking.s_tokenBaseMultiplier(), newValue);
    }
    
    function testSetMultiplierTokenBaseInvalid() public {
        uint256 newValue = monStaking.s_tokenPremiumMultiplier();
    
        vm.startPrank(owner);
        vm.expectRevert(IMonStakingErrors.MonStaking__InvalidTokenBaseMultiplier.selector);
        monStaking.setMultiplier(MonStaking.Multipliers.TOKEN_BASE, newValue);
        vm.stopPrank();
    }
    
    function testSetMultiplierTokenPremiumSuccess() public {
        uint256 newValue = monStaking.s_tokenBaseMultiplier() + 1;
    
        vm.startPrank(owner);
        monStaking.setMultiplier(MonStaking.Multipliers.TOKEN_PREMIUM, newValue);
        vm.stopPrank();
    
        // Verify the new value is set
        assertEq(monStaking.s_tokenPremiumMultiplier(), newValue);
    }
    
    function testSetMultiplierTokenPremiumInvalid() public {
        uint256 newValue = monStaking.s_tokenBaseMultiplier();
    
        vm.startPrank(owner);
        vm.expectRevert(IMonStakingErrors.MonStaking__InvalidTokenPremiumMultiplier.selector);
        monStaking.setMultiplier(MonStaking.Multipliers.TOKEN_PREMIUM, newValue);
        vm.stopPrank();
    }
    
    function testSetMultiplierNftBaseSuccess() public {
        uint256 newValue = 1;
    
        vm.startPrank(owner);
        monStaking.setMultiplier(MonStaking.Multipliers.NFT_BASE, newValue);
        vm.stopPrank();
    
        // Verify the new value is set
        assertEq(monStaking.s_nftBaseMultiplier(), newValue);
    }
    
    function testSetMultiplierNftBaseInvalid() public {
        uint256 newValue = monStaking.s_nftPremiumMultiplier();
    
        vm.startPrank(owner);
        vm.expectRevert(IMonStakingErrors.MonStaking__InvalidNftBaseMultiplier.selector);
        monStaking.setMultiplier(MonStaking.Multipliers.NFT_BASE, newValue);
        vm.stopPrank();
    }
    
    function testSetMultiplierNftPremiumSuccess() public {
        uint256 newValue = monStaking.s_nftBaseMultiplier() + 1;
    
        vm.startPrank(owner);
        monStaking.setMultiplier(MonStaking.Multipliers.NFT_PREMIUM, newValue);
        vm.stopPrank();
    
        // Verify the new value is set
        assertEq(monStaking.s_nftPremiumMultiplier(), newValue);
    }
    
    function testSetMultiplierNftPremiumInvalid() public {
        uint256 newValue = monStaking.s_nftBaseMultiplier();
    
        vm.startPrank(owner);
        vm.expectRevert(IMonStakingErrors.MonStaking__InvalidNftPremiumMultiplier.selector);
        monStaking.setMultiplier(MonStaking.Multipliers.NFT_PREMIUM, newValue);
        vm.stopPrank();
    }
    
    function testSetMultiplierZeroAmount() public {
        uint256 newValue = 0;
    
        vm.startPrank(owner);
        vm.expectRevert(IMonStakingErrors.MonStaking__ZeroAmount.selector);
        monStaking.setMultiplier(MonStaking.Multipliers.TOKEN_BASE, newValue);
        vm.stopPrank();
    }
    
    // hard to get infalid enum error because it errors before out of other stuff
    function testSetMultiplierInvalidMultiplierType() public {
        uint256 newValue = 1;
        
        vm.startPrank(owner);
        // vm.expectRevert(IMonStakingErrors.MonStaking__InvalidMultiplierType.selector);
        vm.expectRevert();
        monStaking.setMultiplier(MonStaking.Multipliers(uint256(4)), newValue); // Invalid enum value
        vm.stopPrank();
    }

    // test function setPeer

    function testSetPeerSuccess() public {
        uint32 eid = 1;
        bytes32 peer = keccak256(abi.encodePacked("peer"));
    
        vm.startPrank(owner);
        monStaking.setPeer(eid, peer);
        vm.stopPrank();
    
        // Verify the peer is set
        assertEq(monStaking.s_otherChainStakingContract(eid), peer);
        assertEq(monStaking.s_supportedChains(0), eid);
    }
    
    function testSetPeerUpdatePeer() public {
        uint32 eid = 1;
        bytes32 peer1 = keccak256(abi.encodePacked("peer1"));
        bytes32 peer2 = keccak256(abi.encodePacked("peer2"));
    
        vm.startPrank(owner);
        monStaking.setPeer(eid, peer1);
        monStaking.setPeer(eid, peer2);
        vm.stopPrank();
    
        // Verify the peer is updated
        assertEq(monStaking.s_otherChainStakingContract(eid), peer2);
        assertEq(monStaking.s_supportedChains(0), eid);
    }
    
    function testSetPeerNotOwner() public {
        uint32 eid = 1;
        bytes32 peer = keccak256(abi.encodePacked("peer"));
    
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        monStaking.setPeer(eid, peer);
        vm.stopPrank();
    }
}