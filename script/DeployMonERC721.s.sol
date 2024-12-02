// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {MonERC721} from "../src/MonERC721.sol";
import {DeployConfig} from "./DeployConfig.s.sol";

/**
 * @dev DeployMonERC721 contract
 * @notice This script is used to deploy MonERC721 contract
 * @notice The .env file must be set with the following variables:
 * @notice ERC721_NAME: The name of the ERC721 token
 * @notice ERC721_SYMBOL: The symbol of the ERC721 token
 * @notice OWNER_NFT: The address of the owner of the NFT
 * @notice TOTAL_SUPPLY: The total supply of the NFT
 * @notice PRICE_IN_NATIVE_TOKEN: The price of the NFT in native token
 * @notice PRICE_IN_MONSTER_TOKEN: The price of the NFT in monster token
 * @notice MONSTER_TOKEN_ADDRESS: The address of the monster token
 * @notice BASE_URI: The base URI of the NFT
 * @notice FUNDS_WALLET: The address of the funds wallet
 * @notice DEPLOYER_PK: The private key of the deployer
 */
contract DeployMonERC721 is DeployConfig {
    MonERC721 public monERC721;

    function deployMonERC721() public returns (address) {
        
        MonERC721Config memory config = getMonERC721Config();

        monERC721 = new MonERC721(
            config.name,
            config.symbol,
            config.owner,
            config.totalSupply,
            config.priceInNativeToken,
            config.priceInMonsterToken,
            config.monsterTokenAddress,
            config.baseURI,
            config.fundsWallet
        );

        return address(monERC721);
    }
}
