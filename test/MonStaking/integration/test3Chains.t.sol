// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

import { Packet } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ISendLib.sol";
import { MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { MessagingReceipt } from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";
import {OAppSender} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";

import {MonStaking} from "../../../src/MonStaking.sol";
import {IMonStakingErrors} from "../../../src/interfaces/errors/IMonStakingErrors.sol";

import "forge-std/console.sol";

import {MonStakingTestBaseIntegrationThreeChains} from "../MonStakingTestBaseIntegration3Chains.t.sol";

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
    /// @dev Simulates message passing from A -> B and A -> C and checks for data integrity.
    function testPingNewChainContractFail() public {
        uint amount = 1000;

        bytes memory message = abi.encode(user, true);

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(150000, 0);
        MessagingFee memory feeToB = monStakingAOApp.quote(bEid, message, options, false);
        MessagingFee memory feeToC = monStakingAOApp.quote(cEid, message, options, false);

        // make the user premium
        vm.startPrank(user);
        monsterTokenA.approve(address(monStakingAOApp), amount);
        vm.expectRevert(abi.encodeWithSelector(OAppSender.NotEnoughNative.selector, feeToB.nativeFee + feeToC.nativeFee));
        monStakingAOApp.stakeTokens{value: feeToB.nativeFee + feeToC.nativeFee}(amount);
        verifyPackets(bEid, addressToBytes32(address(monStakingBOApp)));
    }

    function _stakeTokensAPremium(uint256 amount, uint256 nativeFee) internal {
        monsterTokenA.approve(address(monStakingAOApp), amount);
        monStakingAOApp.stakeTokens{value: nativeFee}(amount);
    }
    
}