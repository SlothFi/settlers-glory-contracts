// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "forge-std/console.sol";

import {MonStaking} from "../src/MonStaking.sol";
import {DeployMonERC721} from "./DeployMonERC721.s.sol";

/**
 * @dev DeployMonStaking contract
 * @notice This script is used to deploy MonStaking contract
 * @notice The .env file must be set with the following variables:
 * @notice OWNER_STAKING: The address of the owner of the staking contract
 * @notice MONSTER_TOKEN_ADDRESS: The address of the monster token
 * @notice MONSTER_NFT_ADDRESS: The address of the monster NFT
 * @notice DELEGATE_REGISTRY_ADDRESS: The address of the delegate registry
 * @notice PREMIUM_MULTIPLIER: The premium multiplier
 * @notice BASE_MULTIPLIER: The base multiplier
 * @notice NFT_MULTIPLIER: The NFT multiplier
 * @notice PREMIUM_NFT_MULTIPLIER: The premium NFT multiplier
 * @notice SECONDS_PER_BLOCK: The seconds per block
 * @notice SECONDS_OF_PREMIUM: The seconds of premium
 * @notice DEPLOYER_PK: The private key of the deployer
 */
contract DeployMonStaking is DeployMonERC721 {
    MonStaking public monStaking;

    function run() public {
        
        MonStaking.Config memory config = getMonStakingConfig();

        uint256 weekUpperBound = getWeekUpperBound();

        vm.startBroadcast();

        address monERC721 = deployMonERC721();

        config.nftToken = monERC721;

        monStaking = new MonStaking(
            config
        );

        // need to have ownership of monStaking
        monStaking.setWeekUpperBound(weekUpperBound);

        console.log("Deployed MonStaking at:", address(monStaking));

        vm.stopBroadcast();
    }
}
