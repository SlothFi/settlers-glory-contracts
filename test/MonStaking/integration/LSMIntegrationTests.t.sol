// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

import { Packet } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ISendLib.sol";
import { MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { MessagingReceipt } from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";
import {OAppSender} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";

import {MonStaking} from "../../../src/MonStaking.sol";
import {LiquidStakedMonster} from "../../../src/LiquidStakedMonster.sol";
import {IMonStakingErrors} from "../../../src/interfaces/errors/IMonStakingErrors.sol";

import "forge-std/console.sol";

import {MonStakingTestBaseIntegration} from "../MonStakingTestBaseIntegration.t.sol";

import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

/// @notice Unit test for MonStaking using the TestHelper.
/// @dev Inherits from TestHelper to utilize its setup and utility functions.
contract LSMIntegrationTests is MonStakingTestBaseIntegration {
    using OptionsBuilder for bytes;

    /// @notice Calls setUp from TestHelper and initializes contract instances for testing.
    function setUp() public virtual override {
        super.setUp();
    }

    function testTransferFromUserToMarketplaceIntegration() public {
        vm.deal(marketPlaceA, 1000000 ether);
        
        uint256 amount = 1000;

        LiquidStakedMonster liquidStakedMonsterA = LiquidStakedMonster(liquidStakedMonsterAddressA);

        bytes memory message = abi.encode(user, true);

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(150000, 0).addExecutorOrderedExecutionOption();
        MessagingFee memory fee = monStakingAOApp.quote(bEid, message, options, false);

        // make the user premium
        vm.startPrank(user);
        _stakeTokensAPremium(amount, fee.nativeFee);

        verifyPackets(bEid, addressToBytes32(address(monStakingBOApp)));
        
        liquidStakedMonsterA.approve(marketPlaceA, amount);

        vm.stopPrank();

        message = abi.encode(user, false);

        fee = monStakingAOApp.quote(bEid, message, options, false);

        vm.startPrank(marketPlaceA);

        liquidStakedMonsterA.transferFrom{value: fee.nativeFee}(amount, user, marketPlaceA);
    }


    function testStakingBalanceAfterTransfer() public {
        vm.deal(marketPlaceA, 1000000 ether);
        
        uint256 amount = 1000;

        LiquidStakedMonster liquidStakedMonsterA = LiquidStakedMonster(liquidStakedMonsterAddressA);

        bytes memory message = abi.encode(user, true);

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(150000, 0).addExecutorOrderedExecutionOption();
        MessagingFee memory fee = monStakingAOApp.quote(bEid, message, options, false);

        // make the user premium
        vm.startPrank(user);
        _stakeTokensAPremium(amount, fee.nativeFee);

        verifyPackets(bEid, addressToBytes32(address(monStakingBOApp)));
        
        assertEq(monStakingAOApp.s_userStakedTokenAmount(user), amount);
        assertEq(monStakingAOApp.s_userStakedTokenAmount(marketPlaceA), 0);

        liquidStakedMonsterA.approve(marketPlaceA, amount);

        vm.stopPrank();

        message = abi.encode(user, false);

        fee = monStakingAOApp.quote(bEid, message, options, false);

        vm.startPrank(marketPlaceA);

        liquidStakedMonsterA.transferFrom{value: fee.nativeFee}(amount, user, marketPlaceA);

        verifyPackets(bEid, addressToBytes32(address(monStakingBOApp)));

        assertEq(monStakingAOApp.s_userStakedTokenAmount(user), 0);
        assertEq(monStakingAOApp.s_userStakedTokenAmount(marketPlaceA), amount);
    }

    function _stakeTokensAPremium(uint256 amount, uint256 nativeFee) internal {
        monsterTokenA.approve(address(monStakingAOApp), amount);
        monStakingAOApp.stakeTokens{value: nativeFee}(amount);
    }
    
}