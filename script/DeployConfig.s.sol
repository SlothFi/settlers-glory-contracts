// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {MonStaking} from "../src/MonStaking.sol";
import {MockMonsterToken} from "../src/mocks/MockMonsterToken.sol";

import {MockLayerZeroEndpointV2} from "../test/MonStaking/helper/mockLayerZeroEndpoint.t.sol";

contract DeployConfig is Script {
    struct MonERC721Config {
        string name;
        string symbol;
        address owner;
        uint256 totalSupply;
        uint256 priceInNativeToken;
        uint256 priceInMonsterToken;
        address monsterTokenAddress;
        string baseURI;
        address fundsWallet;
    }

    function getMonERC721Config() public returns (MonERC721Config memory) {
        if (block.chainid == 42161) { // Arbitrum chain ID
            return MonERC721Config({
                name: vm.envString("ARBITRUM_ERC721_NAME"),
                symbol: vm.envString("ARBITRUM_ERC721_SYMBOL"),
                owner: vm.envAddress("ARBITRUM_OWNER_NFT"),
                totalSupply: vm.envUint("ARBITRUM_TOTAL_SUPPLY"),
                priceInNativeToken: vm.envUint("ARBITRUM_PRICE_IN_NATIVE_TOKEN"),
                priceInMonsterToken: vm.envUint("ARBITRUM_PRICE_IN_MONSTER_TOKEN"),
                monsterTokenAddress: vm.envAddress("ARBITRUM_MONSTER_TOKEN_ADDRESS"),
                baseURI: vm.envString("ARBITRUM_BASE_URI"),
                fundsWallet: vm.envAddress("ARBITRUM_FUNDS_WALLET")
            });
        } else if (block.chainid == 1) { // Ethereum chain ID
            return MonERC721Config({
                name: vm.envString("ETHEREUM_ERC721_NAME"),
                symbol: vm.envString("ETHEREUM_ERC721_SYMBOL"),
                owner: vm.envAddress("ETHEREUM_OWNER_NFT"),
                totalSupply: vm.envUint("ETHEREUM_TOTAL_SUPPLY"),
                priceInNativeToken: vm.envUint("ETHEREUM_PRICE_IN_NATIVE_TOKEN"),
                priceInMonsterToken: vm.envUint("ETHEREUM_PRICE_IN_MONSTER_TOKEN"),
                monsterTokenAddress: vm.envAddress("ETHEREUM_MONSTER_TOKEN_ADDRESS"),
                baseURI: vm.envString("ETHEREUM_BASE_URI"),
                fundsWallet: vm.envAddress("ETHEREUM_FUNDS_WALLET")
            });
        } else { // Local chain

            MockMonsterToken monsterTokenContract = new MockMonsterToken();
            address monsterToken = address(monsterTokenContract);

            return MonERC721Config({
                name: vm.envString("ETHEREUM_ERC721_NAME"),
                symbol: vm.envString("ETHEREUM_ERC721_SYMBOL"),
                owner: vm.envAddress("ETHEREUM_OWNER_NFT"),
                totalSupply: vm.envUint("ETHEREUM_TOTAL_SUPPLY"),
                priceInNativeToken: vm.envUint("ETHEREUM_PRICE_IN_NATIVE_TOKEN"),
                priceInMonsterToken: vm.envUint("ETHEREUM_PRICE_IN_MONSTER_TOKEN"),
                monsterTokenAddress: monsterToken,
                baseURI: vm.envString("ETHEREUM_BASE_URI"),
                fundsWallet: vm.envAddress("ETHEREUM_FUNDS_WALLET")
            });
        }
    }

    function getMonStakingConfig() public returns (MonStaking.Config memory) {
        if (block.chainid == 42161) { // Arbitrum chain ID
            return MonStaking.Config({
                endpoint: vm.envAddress("ARBITRUM_ENDPOINT"),
                delegated: vm.envAddress("ARBITRUM_DELEGATED"),
                premiumDuration: vm.envUint("ARBITRUM_PREMIUM_DURATION"),
                monsterToken: vm.envAddress("ARBITRUM_MONSTER_TOKEN_ADDRESS"),
                nftToken: address(0),
                tokenBaseMultiplier: vm.envUint("ARBITRUM_TOKEN_BASE_MULTIPLIER"),
                tokenPremiumMultiplier: vm.envUint("ARBITRUM_TOKEN_PREMIUM_MULTIPLIER"),
                nftBaseMultiplier: vm.envUint("ARBITRUM_NFT_BASE_MULTIPLIER"),
                nftPremiumMultiplier: vm.envUint("ARBITRUM_NFT_PREMIUM_MULTIPLIER"),
                delegateRegistry: vm.envAddress("ARBITRUM_DELEGATE_REGISTRY_ADDRESS"),
                marketPlace: vm.envAddress("ARBITRUM_MARKET_PLACE"),
                operatorRole: vm.envAddress("ARBITRUM_OPERATOR_ROLE"),
                defaultAdmin: vm.envAddress("ARBITRUM_DEFAULT_ADMIN_ROLE")
            });
        } else if (block.chainid == 1) { // Ethereum chain ID
            return MonStaking.Config({
                endpoint: vm.envAddress("ETHEREUM_ENDPOINT"),
                delegated: vm.envAddress("ETHEREUM_DELEGATED"),
                premiumDuration: vm.envUint("ETHEREUM_PREMIUM_DURATION"),
                monsterToken: vm.envAddress("ETHEREUM_MONSTER_TOKEN_ADDRESS"),
                nftToken: address(0),
                tokenBaseMultiplier: vm.envUint("ETHEREUM_TOKEN_BASE_MULTIPLIER"),
                tokenPremiumMultiplier: vm.envUint("ETHEREUM_TOKEN_PREMIUM_MULTIPLIER"),
                nftBaseMultiplier: vm.envUint("ETHEREUM_NFT_BASE_MULTIPLIER"),
                nftPremiumMultiplier: vm.envUint("ETHEREUM_NFT_PREMIUM_MULTIPLIER"),
                delegateRegistry: vm.envAddress("ETHEREUM_DELEGATE_REGISTRY_ADDRESS"),
                marketPlace: vm.envAddress("ETHEREUM_MARKET_PLACE"),
                operatorRole: vm.envAddress("ETHEREUM_OPERATOR_ROLE"),
                defaultAdmin: vm.envAddress("ETHEREUM_DEFAULT_ADMIN_ROLE")
            });
        } else { // Local chain

            MockLayerZeroEndpointV2 endpoint = new MockLayerZeroEndpointV2();
            address endpointAddress = address(endpoint);

            MockMonsterToken monsterTokenContract = new MockMonsterToken();
            address monsterToken = address(monsterTokenContract);

            return MonStaking.Config({
                endpoint: endpointAddress,
                delegated: vm.envAddress("ETHEREUM_DELEGATED"),
                premiumDuration: vm.envUint("ETHEREUM_PREMIUM_DURATION"),
                monsterToken: monsterToken,
                nftToken: address(0),
                tokenBaseMultiplier: vm.envUint("ETHEREUM_TOKEN_BASE_MULTIPLIER"),
                tokenPremiumMultiplier: vm.envUint("ETHEREUM_TOKEN_PREMIUM_MULTIPLIER"),
                nftBaseMultiplier: vm.envUint("ETHEREUM_NFT_BASE_MULTIPLIER"),
                nftPremiumMultiplier: vm.envUint("ETHEREUM_NFT_PREMIUM_MULTIPLIER"),
                delegateRegistry: vm.envAddress("ETHEREUM_DELEGATE_REGISTRY_ADDRESS"),
                marketPlace: vm.envAddress("ETHEREUM_MARKET_PLACE"),
                operatorRole: vm.envAddress("ETHEREUM_OPERATOR_ROLE"),
                defaultAdmin: vm.envAddress("ETHEREUM_DEFAULT_ADMIN_ROLE")
            });
        }
    }
}