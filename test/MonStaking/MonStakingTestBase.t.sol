// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {MonERC721} from "../../src/MonERC721.sol";
import {MockMonsterToken} from "../../src/mocks/MockMonsterToken.sol";
import {MonStaking} from "../../src/MonStaking.sol";
import {LiquidStakedMonster} from "../../src/LiquidStakedMonster.sol";

import {MockLayerZeroEndpointV2} from "./helper/mockLayerZeroEndpoint.t.sol";
import {MockDelegateRegistry} from "./helper/mockDelegateRegistry.t.sol";

/**
 * @title MonStakingTestBase
 * @dev Base contract for MonStaking tests
 * @dev Contains common setup logic
 */
contract MonStakingTestBase is Test {
    MockMonsterToken public monsterToken;
    LiquidStakedMonster public liquidStakedMonster;
    MonERC721 public monERC721;
    MonStaking public monStaking;
    MockLayerZeroEndpointV2 public mockLayerZeroEndpoint;
    MockDelegateRegistry public mockDelegateRegistry;

    address public monsterTokenAddress;
    address public monERC721Address;
    address public liquidStakedMonsterAddress;
    address public delegateRegistry;

    address public endpoint;
    
    address public user = makeAddr("user");
    address public delegated = makeAddr("delegated");
    address public marketPlace = makeAddr("marketPlace");
    address public owner = delegated;
    address public fundsWallet = makeAddr("fundsWallet");
    
    address public defaultAdminRole = makeAddr("defaultAdminRole");
    address public operatorRole = makeAddr("operatorRole");


    uint256 public premiumDuration = 100;
    uint256 public tokenBaseMultiplier = 1;
    uint256 public tokenPremiumMultiplier = 2;
    uint256 public nftBaseMultiplier = 1;
    uint256 public nftPremiumMultiplier = 2;

    //MonERC721 Config
    uint256 public maxSupply = 10000;
    uint256 public priceInNativeToken = 1000;
    uint256 public priceInMonsterToken = 1;


    function setUp() public virtual {
        // Deploy MockMonsterToken
        monsterToken = new MockMonsterToken();
        monsterTokenAddress = address(monsterToken);

        mockLayerZeroEndpoint = new MockLayerZeroEndpointV2();
        endpoint = address(mockLayerZeroEndpoint);

        mockDelegateRegistry = new MockDelegateRegistry();
        delegateRegistry = address(mockDelegateRegistry);

        // Deploy MonERC721
        monERC721 = new MonERC721(
            "MonERC721",
            "MON",
            owner,
            maxSupply,
            priceInNativeToken,
            priceInMonsterToken,
            monsterTokenAddress,
            "https://api.defimons.com/mon/",
            fundsWallet
        );
        monERC721Address = address(monERC721);

        // Deploy MonStaking
        MonStaking.Config memory config = MonStaking.Config({
            endpoint: endpoint,
            delegated: delegated,
            premiumDuration: premiumDuration,
            monsterToken: monsterTokenAddress,
            nftToken: monERC721Address,
            tokenBaseMultiplier: tokenBaseMultiplier,
            tokenPremiumMultiplier: tokenPremiumMultiplier,
            nftBaseMultiplier: nftBaseMultiplier,
            nftPremiumMultiplier: nftPremiumMultiplier,
            delegateRegistry: delegateRegistry, // Replace with actual delegate registry address if needed
            marketPlace: marketPlace,
            operatorRole: operatorRole,
            defaultAdmin: defaultAdminRole
        });

        monStaking = new MonStaking(config);

        liquidStakedMonsterAddress = monStaking.i_lsToken();
        liquidStakedMonster = LiquidStakedMonster(liquidStakedMonsterAddress);

        // fund the user with some tokens
        monsterToken.mint(user, 10000 ether);

        // fund the user with eth
        vm.deal(user, 1000 ether);
    }
}