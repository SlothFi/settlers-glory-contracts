// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import { Test } from "forge-std/Test.sol";
import "forge-std/console.sol";

import { MonERC721 } from "../../src/MonERC721.sol";
import { MockMonsterToken } from "../../src/mocks/MockMonsterToken.sol";
import { MockToken } from "../../src/mocks/MockToken.sol";
import { MonStaking } from "../../src/MonStaking.sol";
import { LiquidStakedMonster } from "../../src/LiquidStakedMonster.sol";

import { DelegateRegistry } from "@delegate_registry/contracts/DelegateRegistry.sol";

import { TestHelperOz5 } from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";
import { EndpointV2Mock as EndpointV2 } from "@layerzerolabs/test-devtools-evm-foundry/contracts/mocks/EndpointV2Mock.sol";

/**
 * @title MonStakingTestBaseIntegration
 * @dev Base contract for MonStaking tests
 * @dev Contains common setup logic
 */
contract MonStakingTestBaseIntegration is Test, TestHelperOz5 {
    MockToken public mockLzTokenA;
    MockToken public mockLzTokenB;

    MockMonsterToken public monsterTokenA;
    MockMonsterToken public monsterTokenB;
    MonERC721 public monERC721A;
    MonERC721 public monERC721B;

    // Delegate registries
    DelegateRegistry public delegateRegistryContractA;
    DelegateRegistry public delegateRegistryContractB;

    address public monsterTokenAddressA;
    address public monsterTokenAddressB;
    address public monERC721AddressA;
    address public monERC721AddressB;
    address public liquidStakedMonsterAddressA;
    address public liquidStakedMonsterAddressB;
    address public delegateRegistryA;
    address public delegateRegistryB;

    address public endpoint;

    // User address
    address public user = makeAddr("user");

    // Addresses for OApp A
    address public marketPlaceA = makeAddr("marketPlaceA");
    address public fundsWalletA = makeAddr("fundsWalletA");
    address public defaultAdminRoleA = makeAddr("defaultAdminRoleA");
    address public operatorRoleA = makeAddr("operatorRoleA");

    // Owner addresses
    address public delegatedA = address(this);
    address public ownerA = delegatedA;

    // Addresses for OApp B
    address public delegatedB = delegatedA;
    address public marketPlaceB = makeAddr("marketPlaceB");
    address public ownerB = delegatedB;
    address public fundsWalletB = makeAddr("fundsWalletB");
    address public defaultAdminRoleB = makeAddr("defaultAdminRoleB");
    address public operatorRoleB = makeAddr("operatorRoleB");

    uint256 public premiumDuration = 100;
    uint256 public tokenBaseMultiplier = 1;
    uint256 public tokenPremiumMultiplier = 2;
    uint256 public nftBaseMultiplier = 1;
    uint256 public nftPremiumMultiplier = 2;

    // MonERC721 Config
    uint256 public maxSupply = 10000;
    uint256 public priceInNativeToken = 1000;
    uint256 public priceInMonsterToken = 1;

    // LayerZero OApps configuration
    uint16 aEid = 1;
    uint16 bEid = 2;

    // Declaration of mock contracts
    MonStaking monStakingAOApp; // OApp A
    MonStaking monStakingBOApp; // OApp B

    function setUp() public virtual override {
        super.setUp();

        fundUser();

        deployMockTokens();

        deployDelegateRegistries();

        deployMonERC721Contracts();

        setUpEndpoints(2, LibraryType.SimpleMessageLib);

        deployMonStakingOApps();

        wireOApps();

        getLiquidStakingTokenAddresses();

        setUpMockLzTokens();
    }

    function fundUser() internal {
        // Funding the user
        vm.deal(user, 1000000 ether);
    }

    function deployMockTokens() internal {
        // Deploy mock LayerZero tokens
        mockLzTokenA = new MockToken("MockLzTokenA", "MLZTA");
        mockLzTokenB = new MockToken("MockLzTokenB", "MLZTB");

        // Deploy MockMonsterToken for OApp A
        monsterTokenA = new MockMonsterToken();
        monsterTokenAddressA = address(monsterTokenA);
        monsterTokenA.mint(user, 10000 ether);
        monsterTokenA.mint(marketPlaceA, 10000 ether);

        // Deploy MockMonsterToken for OApp B
        monsterTokenB = new MockMonsterToken();
        monsterTokenAddressB = address(monsterTokenB);
        monsterTokenB.mint(user, 10000 ether);
    }

    function deployDelegateRegistries() internal {
        // Deploy a delegate registry for OApp A
        delegateRegistryContractA = new DelegateRegistry();
        delegateRegistryA = address(delegateRegistryContractA);

        // Deploy a delegate registry for OApp B
        delegateRegistryContractB = new DelegateRegistry();
        delegateRegistryB = address(delegateRegistryContractB);
    }

    function deployMonERC721Contracts() internal {
        // Deploy MonERC721 for OApp A
        monERC721A = new MonERC721(
            "MonERC721A",
            "MONA",
            ownerA,
            maxSupply,
            priceInNativeToken,
            priceInMonsterToken,
            monsterTokenAddressA,
            "https://api.defimons.com/mon/",
            fundsWalletA
        );
        monERC721AddressA = address(monERC721A);

        // Deploy MonERC721 for OApp B
        monERC721B = new MonERC721(
            "MonERC721B",
            "MONB",
            ownerB,
            maxSupply,
            priceInNativeToken,
            priceInMonsterToken,
            monsterTokenAddressB,
            "https://api.defimons.com/mon/",
            fundsWalletB
        );
        monERC721AddressB = address(monERC721B);
    }

    // issue with stack too deep because of number of parameters , need to do struct but doesn't work in _deployOApp

    function deployMonStakingOApps() internal {
        // Deploying the MonStaking OApps
        monStakingAOApp = MonStaking(
            _deployOApp(
                type(MonStaking).creationCode,
                abi.encode(
                    endpoints[aEid],
                    address(this),
                    premiumDuration,
                    monsterTokenAddressA,
                    monERC721AddressA,
                    tokenBaseMultiplier,
                    tokenPremiumMultiplier,
                    nftBaseMultiplier,
                    nftPremiumMultiplier,
                    delegateRegistryA,
                    marketPlaceA,
                    operatorRoleA,
                    defaultAdminRoleA
                )
            )
        );

        monStakingBOApp = MonStaking(
            _deployOApp(
                type(MonStaking).creationCode,
                abi.encode(
                    endpoints[bEid],
                    address(this),
                    premiumDuration,
                    monsterTokenAddressB,
                    monERC721AddressB,
                    tokenBaseMultiplier,
                    tokenPremiumMultiplier,
                    nftBaseMultiplier,
                    nftPremiumMultiplier,
                    delegateRegistryB,
                    marketPlaceB,
                    operatorRoleB,
                    defaultAdminRoleB
                )
            )
        );
    }

    function wireOApps() internal {
        // Manual wiring of the OApps
        monStakingAOApp.setPeer(uint32(bEid), bytes32(uint(uint160(address(monStakingBOApp)))));
        monStakingBOApp.setPeer(uint32(aEid), bytes32(uint(uint160(address(monStakingAOApp)))));
    }

    function getLiquidStakingTokenAddresses() internal {
        // Getting the liquid staking token addresses
        liquidStakedMonsterAddressA = monStakingAOApp.i_lsToken();
        liquidStakedMonsterAddressB = monStakingBOApp.i_lsToken();
    }

    function setUpMockLzTokens() internal {
        // Setting up mock LayerZero tokens
        EndpointV2(endpoints[aEid]).setLzToken(address(mockLzTokenA));
        EndpointV2(endpoints[bEid]).setLzToken(address(mockLzTokenB));
    }
}
