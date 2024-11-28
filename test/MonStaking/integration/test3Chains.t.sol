// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

import { Packet } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ISendLib.sol";
import { MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { Origin } from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppReceiver.sol"; 
import { MessagingReceipt } from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";
import {OAppSender} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";

import {MonStaking} from "../../../src/MonStaking.sol";
import {IMonStakingErrors} from "../../../src/interfaces/errors/IMonStakingErrors.sol";

import "forge-std/console.sol";

import {MonStakingTestBaseIntegrationThreeChains} from "../MonStakingTestBaseIntegration3Chains.t.sol";
import {TestHelperOz5} from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

/// @notice Unit test for MonStaking using the TestHelper.
/// @dev Inherits from TestHelper to utilize its setup and utility functions.
contract testThreeChains is MonStakingTestBaseIntegrationThreeChains {
    using OptionsBuilder for bytes;

    /// @notice Calls setUp from TestHelper and initializes contract instances for testing.
    function setUp() public virtual override {
        super.setUp();
    }

    /// @notice Tests the send functionality of MonStaking.
    /// @dev Simulates message passing from A -> B and A -> C.
    function testPingMultipleChainsSucceeds() public {
        uint amount = 1000;
        bytes32 aOappAddrInBytes = bytes32(uint256(uint160(address(monStakingAOApp))));

        bytes memory message = abi.encode(user, true);

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(150000, 0).addExecutorOrderedExecutionOption();
        MessagingFee memory feeToB = monStakingAOApp.quote(bEid, message, options, false);
        MessagingFee memory feeToC = monStakingAOApp.quote(cEid, message, options, false);

        // make the user premium
        vm.startPrank(user);
        monsterTokenA.approve(address(monStakingAOApp), amount);

        monStakingAOApp.stakeTokens{value: feeToB.nativeFee + feeToC.nativeFee}(amount);
        verifyPackets(bEid, addressToBytes32(address(monStakingBOApp)));
        verifyPackets(cEid, addressToBytes32(address(monStakingCOApp)));

        // check that message is received by B
        assertEq(monStakingBOApp.s_isUserPremium(user), true);
        assertEq(monStakingBOApp.s_userLastUpdatedTimestamp(user), block.timestamp);

        // check that message is received by C
        assertEq(monStakingCOApp.s_isUserPremium(user), true);
        assertEq(monStakingCOApp.s_userLastUpdatedTimestamp(user), block.timestamp);

        console.log("boapp: ", monStakingBOApp.receivedNonce(aEid, aOappAddrInBytes));
        console.log("cOapp: ", monStakingCOApp.receivedNonce(aEid, aOappAddrInBytes));

        assertEq(monStakingBOApp.receivedNonce(aEid, aOappAddrInBytes), 1);
        assertEq(monStakingCOApp.receivedNonce(aEid, aOappAddrInBytes), 1);
    }

    /// @notice Tests the send functionality of MonStaking.
    /// @dev Simulates message passing from A -> B and A -> C.
    function testNonceIncrementingCorrectly() public {
        uint amount = 1000;
        bytes32 aOappAddrInBytes = bytes32(uint256(uint160(address(monStakingAOApp))));

        bytes memory message = abi.encode(user, true);

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(150000, 0).addExecutorOrderedExecutionOption();
        MessagingFee memory feeToB = monStakingAOApp.quote(bEid, message, options, false);
        MessagingFee memory feeToC = monStakingAOApp.quote(cEid, message, options, false);

        vm.startPrank(user);
        monsterTokenA.approve(address(monStakingAOApp), amount);

        monStakingAOApp.stakeTokens{value: feeToB.nativeFee + feeToC.nativeFee}(amount);
        vm.stopPrank();

        verifyPackets(bEid, addressToBytes32(address(monStakingBOApp)));
        verifyPackets(cEid, addressToBytes32(address(monStakingCOApp)));

        assertEq(monStakingBOApp.receivedNonce(aEid, aOappAddrInBytes), 1);
        assertEq(monStakingCOApp.receivedNonce(aEid, aOappAddrInBytes), 1);

        // stake again and see that the nonce is incremented in both chains
        vm.startPrank(user2);
        monsterTokenA.approve(address(monStakingAOApp), amount);

        monStakingAOApp.stakeTokens{value: feeToB.nativeFee + feeToC.nativeFee}(amount);
        vm.stopPrank();

        verifyPackets(bEid, addressToBytes32(address(monStakingBOApp)));
        verifyPackets(cEid, addressToBytes32(address(monStakingCOApp)));

        assertEq(monStakingBOApp.receivedNonce(aEid, aOappAddrInBytes), 2);
        assertEq(monStakingCOApp.receivedNonce(aEid, aOappAddrInBytes), 2);
    }

    function testNonceOrderingEnforced() public {
        bytes32 aOappAddrInBytes = bytes32(uint256(uint160(address(monStakingAOApp))));

        bytes memory message = abi.encode(user, true);

        // Simulate receiving messages in the wrong order

        // the first message from AOapp -> BOapp
        Origin memory firstOrigin = Origin({
            srcEid: aEid,
            sender: aOappAddrInBytes,
            nonce: 1
        });
        
        // the second message from AOapp -> BOapp
        Origin memory secondOrigin = Origin({
            srcEid: aEid,
            sender: aOappAddrInBytes,
            nonce: 2 
        });

        vm.startPrank(endpoints[bEid]);

        // the second message is received first
        vm.expectRevert(IMonStakingErrors.MonStaking_InvalidNonce.selector);
        monStakingBOApp.lzReceive(secondOrigin, bytes32(0), message, address(0), bytes(""));

        // then first message is received second
        monStakingBOApp.lzReceive(firstOrigin, bytes32(0), message, address(0), bytes(""));
    }

    function testNonceOrderingWithMultipleMessages() public {
        bytes32 aOappAddrInBytes = bytes32(uint256(uint160(address(monStakingAOApp))));
    
        bytes memory message = abi.encode(user, true);
    
        // Simulate receiving multiple messages in the correct order
        Origin memory firstOrigin = Origin({
            srcEid: aEid,
            sender: aOappAddrInBytes,
            nonce: 1
        });
    
        Origin memory secondOrigin = Origin({
            srcEid: aEid,
            sender: aOappAddrInBytes,
            nonce: 2
        });
    
        Origin memory thirdOrigin = Origin({
            srcEid: aEid,
            sender: aOappAddrInBytes,
            nonce: 3
        });
    
        vm.startPrank(endpoints[bEid]);
    
        // Receive messages in the correct order
        monStakingBOApp.lzReceive(firstOrigin, bytes32(0), message, address(0), bytes(""));
        monStakingBOApp.lzReceive(secondOrigin, bytes32(0), message, address(0), bytes(""));
        monStakingBOApp.lzReceive(thirdOrigin, bytes32(0), message, address(0), bytes(""));
    
        // Check that the nonce is incremented correctly
        assertEq(monStakingBOApp.receivedNonce(aEid, aOappAddrInBytes), 3);
    }
    
    function testNonceOrderingWithSkippedNonce() public {
        bytes32 aOappAddrInBytes = bytes32(uint256(uint160(address(monStakingAOApp))));
    
        bytes memory message = abi.encode(user, true);
    
        // Simulate receiving messages with a skipped nonce
        Origin memory firstOrigin = Origin({
            srcEid: aEid,
            sender: aOappAddrInBytes,
            nonce: 1
        });
    
        Origin memory thirdOrigin = Origin({
            srcEid: aEid,
            sender: aOappAddrInBytes,
            nonce: 3
        });
    
        vm.startPrank(endpoints[bEid]);
    
        // Receive the first message
        monStakingBOApp.lzReceive(firstOrigin, bytes32(0), message, address(0), bytes(""));
    
        // Expect revert when receiving the third message (skipped nonce)
        vm.expectRevert(IMonStakingErrors.MonStaking_InvalidNonce.selector);
        monStakingBOApp.lzReceive(thirdOrigin, bytes32(0), message, address(0), bytes(""));
    }
    
    function testNonceOrderingWithCorrectSequence() public {
        bytes32 aOappAddrInBytes = bytes32(uint256(uint160(address(monStakingAOApp))));
    
        bytes memory message = abi.encode(user, true);
    
        // Simulate receiving messages in the correct sequence
        Origin memory firstOrigin = Origin({
            srcEid: aEid,
            sender: aOappAddrInBytes,
            nonce: 1
        });
    
        Origin memory secondOrigin = Origin({
            srcEid: aEid,
            sender: aOappAddrInBytes,
            nonce: 2
        });
    
        Origin memory thirdOrigin = Origin({
            srcEid: aEid,
            sender: aOappAddrInBytes,
            nonce: 3
        });
    
        vm.startPrank(endpoints[bEid]);
    
        // Receive messages in the correct order
        monStakingBOApp.lzReceive(firstOrigin, bytes32(0), message, address(0), bytes(""));
        monStakingBOApp.lzReceive(secondOrigin, bytes32(0), message, address(0), bytes(""));
        monStakingBOApp.lzReceive(thirdOrigin, bytes32(0), message, address(0), bytes(""));
    
        // Check that the nonce is incremented correctly
        assertEq(monStakingBOApp.receivedNonce(aEid, aOappAddrInBytes), 3);
    }
    
    function testNonceOrderingWithDuplicateNonce() public {
        bytes32 aOappAddrInBytes = bytes32(uint256(uint160(address(monStakingAOApp))));
    
        bytes memory message = abi.encode(user, true);
    
        // Simulate receiving messages with a duplicate nonce
        Origin memory firstOrigin = Origin({
            srcEid: aEid,
            sender: aOappAddrInBytes,
            nonce: 1
        });
    
        Origin memory duplicateOrigin = Origin({
            srcEid: aEid,
            sender: aOappAddrInBytes,
            nonce: 1
        });
    
        vm.startPrank(endpoints[bEid]);
    
        // Receive the first message
        monStakingBOApp.lzReceive(firstOrigin, bytes32(0), message, address(0), bytes(""));
    
        // Expect revert when receiving the duplicate message
        vm.expectRevert(IMonStakingErrors.MonStaking_InvalidNonce.selector);
        monStakingBOApp.lzReceive(duplicateOrigin, bytes32(0), message, address(0), bytes(""));
    }

    function _stakeTokensAPremium(uint256 amount, uint256 nativeFee) internal {
        monsterTokenA.approve(address(monStakingAOApp), amount);
        monStakingAOApp.stakeTokens{value: nativeFee}(amount);
    }
    
}