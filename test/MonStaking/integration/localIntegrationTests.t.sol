// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

import { Packet } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ISendLib.sol";
import { MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { MessagingReceipt } from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";
import {OAppSender} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";

import {MonStaking} from "../../../src/MonStaking.sol";
import {IMonStakingErrors} from "../../../src/interfaces/errors/IMonStakingErrors.sol";

import "forge-std/console.sol";

import {MonStakingTestBaseIntegration} from "../MonStakingTestBaseIntegration.t.sol";

import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

/// @notice Unit test for MonStaking using the TestHelper.
/// @dev Inherits from TestHelper to utilize its setup and utility functions.
contract LocalIntegrationTests is MonStakingTestBaseIntegration {
    using OptionsBuilder for bytes;

    /// @notice Calls setUp from TestHelper and initializes contract instances for testing.
    function setUp() public virtual override {
        super.setUp();
    }

    /// @notice Tests the send functionality of MonStaking.
    /// @dev Simulates message passing from A -> B and checks for data integrity.
    function testPingNewChainContractSuccess() public {
        bytes memory message = abi.encode(user, true);

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(150000, 0);
        MessagingFee memory fee = monStakingAOApp.quote(bEid, message, options, false);

        // make the user premium
        vm.startPrank(user);
        _stakeTokensAPremium(1000, fee.nativeFee);

        verifyPackets(bEid, addressToBytes32(address(monStakingBOApp)));

        monStakingAOApp.pingNewChainContract{value: fee.nativeFee}(uint32(bEid));

        //Deliver packet to monStakingBOapp manually.
        verifyPackets(bEid, addressToBytes32(address(monStakingBOApp)));

        // check that the user became premium and that we updated the timestamp
        assertEq(monStakingBOApp.s_isUserPremium(user), true);
        assertEq(monStakingBOApp.s_userLastUpdatedTimestamp(user), block.timestamp);
    }

    function testPingNewChainContractPayLzToken() public {
        bytes memory message = abi.encode(user, true);

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(150000, 0);
        MessagingFee memory fee = monStakingAOApp.quote(bEid, message, options, true);
        
        // make the user premium
        vm.startPrank(user);
        mockLzTokenA.approve(address(monStakingAOApp), fee.lzTokenFee);
        _stakeTokensAPremium(1000, fee.nativeFee);

        verifyPackets(bEid, addressToBytes32(address(monStakingBOApp)));

        mockLzTokenA.approve(address(monStakingAOApp), fee.lzTokenFee);
        monStakingAOApp.pingNewChainContract{value: fee.nativeFee}(uint32(bEid));

        //Deliver packet to monStakingBOapp manually.
        verifyPackets(bEid, addressToBytes32(address(monStakingBOApp)));

        // check that the user became premium and that we updated the timestamp
        assertEq(monStakingBOApp.s_isUserPremium(user), true);
        assertEq(monStakingBOApp.s_userLastUpdatedTimestamp(user), block.timestamp);
    }

    function testPingNewChainContractUserAlreadyPremium() public {
        bytes memory message = abi.encode(user, true);

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(150000, 0);
        MessagingFee memory fee = monStakingAOApp.quote(bEid, message, options, false);

        // make the user premium
        vm.startPrank(user);
        _stakeTokensAPremium(1000, fee.nativeFee);

        verifyPackets(bEid, addressToBytes32(address(monStakingBOApp)));

        vm.expectRevert(IMonStakingErrors.MonStaking__UserAlreadyPremium.selector);
        monStakingBOApp.pingNewChainContract{value: fee.nativeFee}(uint32(aEid));
    }

    // shows that OAppSender handles fee calculation 
    function testLzSendNotEnoughNative() public {
        bytes memory message = abi.encode(user, true);

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(150000, 0);
        MessagingFee memory fee = monStakingAOApp.quote(bEid, message, options, false);

        // make a user premium
        vm.startPrank(user);
        _stakeTokensAPremium(1000, fee.nativeFee);

        verifyPackets(bEid, addressToBytes32(address(monStakingBOApp)));

        // fail if user gives less than fee
        vm.expectRevert(abi.encodeWithSelector(OAppSender.NotEnoughNative.selector, fee.nativeFee - 1));
        monStakingAOApp.pingNewChainContract{value: fee.nativeFee - 1}(uint32(bEid));

        // fail if user gives more than fee
        vm.expectRevert(abi.encodeWithSelector(OAppSender.NotEnoughNative.selector, fee.nativeFee + 1));
        monStakingAOApp.pingNewChainContract{value: fee.nativeFee + 1}(uint32(bEid));
    }

    // tests for _updateOtherChains function
    function testUpdateOtherChainsNotEnoughNative() public {
        uint amount = 999;
        bytes memory message = abi.encode(user, true);

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(150000, 0);
        MessagingFee memory fee = monStakingAOApp.quote(bEid, message, options, false);

        // fail if user gives less than fee
        vm.startPrank(user);
        monsterTokenA.approve(address(monStakingAOApp), amount);
        vm.expectRevert(abi.encodeWithSelector(IMonStakingErrors.MonStaking__NotEnoughNativeTokens.selector, fee.nativeFee));
        monStakingAOApp.stakeTokens{value: fee.nativeFee - 1}(amount);
    }

    function testUpdateOtherChainsPayLzToken() public {
        bytes memory message = abi.encode(user, true);

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(150000, 0);
        MessagingFee memory fee = monStakingAOApp.quote(bEid, message, options, true);
        
        // fail if user gives less than fee
        vm.startPrank(user);
        mockLzTokenA.approve(address(monStakingAOApp), fee.lzTokenFee);
        _stakeTokensAPremium(1000, fee.nativeFee);

        verifyPackets(bEid, addressToBytes32(address(monStakingBOApp)));

        assertEq(monStakingBOApp.s_isUserPremium(user), true);
        assertEq(monStakingBOApp.s_userLastUpdatedTimestamp(user), block.timestamp);
    }

    function testUpdateOtherChainsNotPremium() public {
        bytes memory message = abi.encode(user, true);

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(150000, 0);
        MessagingFee memory fee = monStakingAOApp.quote(bEid, message, options, false);
        
        // fail if user gives less than fee
        vm.startPrank(user);
        _stakeTokensAPremium(1000, fee.nativeFee);
        
        verifyPackets(bEid, addressToBytes32(address(monStakingBOApp)));

        monStakingAOApp.requireUnstakeAll{value : fee.nativeFee}();
        verifyPackets(bEid, addressToBytes32(address(monStakingBOApp)));

        assertEq(monStakingBOApp.s_isUserPremium(user), false);
        assertEq(monStakingBOApp.s_userLastUpdatedTimestamp(user), block.timestamp);
    }

    function testRequireUnstakeAllZeroAmount() public {
        bytes memory message = abi.encode(user, true);

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(150000, 0);
        MessagingFee memory fee = monStakingAOApp.quote(bEid, message, options, false);
        
        vm.startPrank(user);
        _stakeTokensAPremium(1000, fee.nativeFee);

        verifyPackets(bEid, addressToBytes32(address(monStakingBOApp)));

        // the user is premium on the other chain without staking anything
        assertEq(monStakingBOApp.s_isUserPremium(user), true);
        assertEq(monStakingBOApp.s_userLastUpdatedTimestamp(user), block.timestamp);

        vm.expectRevert(IMonStakingErrors.MonStaking__ZeroAmount.selector);
        monStakingBOApp.requireUnstakeAll{value : fee.nativeFee}();
    }

    //call other functions with _lzsend from both a and b and _lzReceive

    function _stakeTokensAPremium(uint256 amount, uint256 nativeFee) internal {
        monsterTokenA.approve(address(monStakingAOApp), amount);
        monStakingAOApp.stakeTokens{value: nativeFee}(amount);
    }
    
    function _stakeTokensANotPremium(uint256 amount, uint256 nativeFee) internal {
        vm.warp(monStakingAOApp.i_endPremiumTimestamp() + 1);
        monsterTokenA.approve(address(monStakingAOApp), amount);
        monStakingAOApp.stakeTokens{value: nativeFee}(amount);
    }
    
    function _stakeTokensBPremium(uint256 amount, uint256 nativeFee) internal {
        monsterTokenB.approve(address(monStakingBOApp), amount);
        monStakingBOApp.stakeTokens{value: nativeFee}(amount);
    }
    
    function _stakeTokensBNotPremium(uint256 amount, uint256 nativeFee) internal {
        vm.warp(monStakingBOApp.i_endPremiumTimestamp() + 1);
        monsterTokenB.approve(address(monStakingBOApp), amount);
        monStakingBOApp.stakeTokens{value: nativeFee}(amount);
    }
}