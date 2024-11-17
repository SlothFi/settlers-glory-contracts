// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {MonStakingTestBase} from "../MonStakingTestBase.t.sol";
import {MockMonsterToken} from "../../../src/mocks/MockMonsterToken.sol";
import {MonStaking} from "../../../src/MonStaking.sol";
import {LiquidStakedMonster} from "../../../src/LiquidStakedMonster.sol";
import {IMonStakingErrors} from "../../../src/interfaces/errors/IMonStakingErrors.sol";
import {IMonStakingEvents} from "../../../src/interfaces/events/IMonStakingEvents.sol";

import {MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";

/**
 * @title CrossChainTests
 * @dev Tests for cross-chain functionality in MonStaking
 */
contract CrossChainTests is MonStakingTestBase {

    function setUp() public override {
        super.setUp();
    }

    // function testPingNewChainContractSuccess() public {
    //     uint256 amount = 1000 * 10 ** 18;
    //     uint32[] memory chainIds = new uint32[](1);
    //     chainIds[0] = 1;

    //     // Add a supported chain
    //     bytes32[] memory peers = new bytes32[](1);
    //     peers[0] = keccak256(abi.encodePacked("peer"));

    //     vm.startPrank(owner);
    //     monStaking.batchSetPeers(chainIds, peers);
    //     vm.stopPrank();

    //     // Stake tokens to make user premium
    //     vm.startPrank(user);
    //     monsterToken.approve(address(monStaking), amount);
    //     monStaking.stakeTokens(amount);

    //     // Ping new chain contract
    //     monStaking.pingNewChainContract{value: 100 ether}(chainIds[0]);
    //     vm.stopPrank();

    //     // Verify event emitted
    //     vm.expectEmit(true, true, true, true);
    //     emit IMonStakingEvents.NewChainPinged(chainIds[0], user);
    // }

    function testPingNewChainContractZeroChainId() public {
        uint32 chainId = 0;

        vm.startPrank(user);
        vm.expectRevert(IMonStakingErrors.MonStaking__ZeroChainId.selector);
        monStaking.pingNewChainContract{value: 1 ether}(chainId);
        vm.stopPrank();
    }

    function testPingNewChainContractChainNotSupported() public {
        uint32 chainId = 1;

        vm.startPrank(user);
        vm.expectRevert(IMonStakingErrors.MonStaking__ChainNotSupported.selector);
        monStaking.pingNewChainContract{value: 1 ether}(chainId);
        vm.stopPrank();
    }

    // function testPingNewChainContractUserAlreadyPremium() public {
    //     uint256 amount = 1000 * 10 ** 18;
    //     uint32[] memory chainIds = new uint32[](1);
    //     chainIds[0] = 1;

    //     // Add a supported chain
    //     bytes32[] memory peers = new bytes32[](1);
    //     peers[0] = keccak256(abi.encodePacked("peer"));

    //     vm.startPrank(owner);
    //     monStaking.batchSetPeers(chainIds, peers);
    //     vm.stopPrank();

    //     // Stake tokens to make user premium
    //     vm.startPrank(user);
    //     monsterToken.approve(address(monStaking), amount);
    //     monStaking.stakeTokens(amount);

    //     // Ping new chain contract
    //     monStaking.pingNewChainContract{value: 1 ether}(chainIds[0]);

    //     // Attempt to ping the same chain again
    //     vm.expectRevert(IMonStakingErrors.MonStaking__UserAlreadyPremium.selector);
    //     monStaking.pingNewChainContract{value: 1 ether}(chainIds[0]);
    //     vm.stopPrank();
    // }

    function testPingNewChainContractUserNotPremium() public {
        uint32[] memory chainIds = new uint32[](1);
        chainIds[0] = 1;

        // Add a supported chain
        bytes32[] memory peers = new bytes32[](1);
        peers[0] = keccak256(abi.encodePacked("peer"));

        vm.startPrank(owner);
        monStaking.batchSetPeers(chainIds, peers);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert(IMonStakingErrors.MonStaking__UserNotPremium.selector);
        monStaking.pingNewChainContract{value: 1 ether}(chainIds[0]);
        vm.stopPrank();
    }

    // function testPingNewChainContractTransferFailed() public {
    //     uint256 amount = 1000 * 10 ** 18;
    //     uint32[] memory chainIds = new uint32[](1);
    //     chainIds[0] = 1;

    //     // Add a supported chain
    //     bytes32[] memory peers = new bytes32[](1);
    //     peers[0] = keccak256(abi.encodePacked("peer"));

    //     vm.startPrank(owner);
    //     monStaking.batchSetPeers(chainIds, peers);
    //     vm.stopPrank();

    //     // Stake tokens to make user premium
    //     vm.startPrank(user);
    //     monsterToken.approve(address(monStaking), amount);
    //     monStaking.stakeTokens(amount);

    //     // Mock the _quote function to return a high native fee
    //     vm.mockCall(
    //         address(monStaking),
    //         abi.encodeWithSelector(monStaking._quote.selector, chainIds[0], abi.encode(user, true), "", false),
    //         abi.encode(MessagingFee({nativeFee: 2 ether, lzTokenFee: 0}))
    //     );

    //     // Attempt to ping new chain contract with insufficient value
    //     vm.expectRevert(IMonStakingErrors.MonStaking__TransferFailed.selector);
    //     monStaking.pingNewChainContract{value: 1 ether}(chainIds[0]);
    //     vm.stopPrank();
    // }
}