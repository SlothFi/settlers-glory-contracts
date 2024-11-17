// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {MonStakingTestBase} from "../MonStakingTestBase.t.sol";
import {MonStaking} from "../../../src/MonStaking.sol";
import {MockMonsterToken} from "../../../src/mocks/MockMonsterToken.sol";

import {IMonStakingErrors} from "../../../src/interfaces/errors/IMonStakingErrors.sol";

/**
 * @title ConstructorTests
 * @dev Tests for the constructor of MonStaking
 */
contract ConstructorTests is MonStakingTestBase {

    function setUp() public override {
        super.setUp();
    }

    function testConstructorSuccess() public {
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
            delegateRegistry: address(0x1), 
            marketPlace: marketPlace,
            operatorRole: operatorRole,
            defaultAdmin: defaultAdminRole
        });

        MonStaking staking = new MonStaking(config);

        assertEq(staking.i_monsterToken(), monsterTokenAddress);
        assertEq(staking.i_nftToken(), monERC721Address);
        // assertEq(staking.i_delegateRegistry(), address(0x1));
        assertEq(staking.i_premiumDuration(), premiumDuration);
        assertEq(staking.s_tokenBaseMultiplier(), tokenBaseMultiplier);
        assertEq(staking.s_tokenPremiumMultiplier(), tokenPremiumMultiplier);
        assertEq(staking.s_nftBaseMultiplier(), nftBaseMultiplier);
        assertEq(staking.s_nftPremiumMultiplier(), nftPremiumMultiplier);
    }

    function testConstructorRevertInvalidMonsterToken() public {
        MonStaking.Config memory config = MonStaking.Config({
            endpoint: endpoint,
            delegated: delegated,
            premiumDuration: premiumDuration,
            monsterToken: address(0),
            nftToken: monERC721Address,
            tokenBaseMultiplier: tokenBaseMultiplier,
            tokenPremiumMultiplier: tokenPremiumMultiplier,
            nftBaseMultiplier: nftBaseMultiplier,
            nftPremiumMultiplier: nftPremiumMultiplier,
            delegateRegistry: address(0x1),
            marketPlace: marketPlace,
            operatorRole: operatorRole,
            defaultAdmin: defaultAdminRole
        });

        vm.expectRevert(IMonStakingErrors.MonStaking__ZeroAddress.selector);
        new MonStaking(config);
    }

    function testConstructorRevertInvalidNftToken() public {
        MonStaking.Config memory config = MonStaking.Config({
            endpoint: endpoint,
            delegated: delegated,
            premiumDuration: premiumDuration,
            monsterToken: monsterTokenAddress,
            nftToken: address(0),
            tokenBaseMultiplier: tokenBaseMultiplier,
            tokenPremiumMultiplier: tokenPremiumMultiplier,
            nftBaseMultiplier: nftBaseMultiplier,
            nftPremiumMultiplier: nftPremiumMultiplier,
            delegateRegistry: address(0x1), 
            marketPlace: marketPlace,
            operatorRole: operatorRole,
            defaultAdmin: defaultAdminRole
        });

        vm.expectRevert(IMonStakingErrors.MonStaking__ZeroAddress.selector);
        new MonStaking(config);
    }

    function testConstructorRevertInvalidDelegateRegistry() public {
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
            delegateRegistry: address(0),
            marketPlace: marketPlace,
            operatorRole: operatorRole,
            defaultAdmin: defaultAdminRole
        });

        vm.expectRevert(IMonStakingErrors.MonStaking__ZeroAddress.selector);
        new MonStaking(config);
    }

    function testConstructorRevertInvalidPremiumDuration() public {
        MonStaking.Config memory config = MonStaking.Config({
            endpoint: endpoint,
            delegated: delegated,
            premiumDuration: 0,
            monsterToken: monsterTokenAddress,
            nftToken: monERC721Address,
            tokenBaseMultiplier: tokenBaseMultiplier,
            tokenPremiumMultiplier: tokenPremiumMultiplier,
            nftBaseMultiplier: nftBaseMultiplier,
            nftPremiumMultiplier: nftPremiumMultiplier,
            delegateRegistry: address(0x1), 
            marketPlace: marketPlace,
            operatorRole: operatorRole,
            defaultAdmin: defaultAdminRole
        });

        vm.expectRevert(IMonStakingErrors.MonStaking__ZeroAmount.selector);
        new MonStaking(config);
    }

    function testConstructorRevertInvalidTokenBaseMultiplier() public {
        MonStaking.Config memory config = MonStaking.Config({
            endpoint: endpoint,
            delegated: delegated,
            premiumDuration: premiumDuration,
            monsterToken: monsterTokenAddress,
            nftToken: monERC721Address,
            tokenBaseMultiplier: 0,
            tokenPremiumMultiplier: tokenPremiumMultiplier,
            nftBaseMultiplier: nftBaseMultiplier,
            nftPremiumMultiplier: nftPremiumMultiplier,
            delegateRegistry: address(0x1), 
            marketPlace: marketPlace,
            operatorRole: operatorRole,
            defaultAdmin: defaultAdminRole
        });

        vm.expectRevert(IMonStakingErrors.MonStaking__InvalidTokenBaseMultiplier.selector);
        new MonStaking(config);
    }

    function testConstructorRevertInvalidTokenPremiumMultiplier() public {
        MonStaking.Config memory config = MonStaking.Config({
            endpoint: endpoint,
            delegated: delegated,
            premiumDuration: premiumDuration,
            monsterToken: monsterTokenAddress,
            nftToken: monERC721Address,
            tokenBaseMultiplier: tokenBaseMultiplier,
            tokenPremiumMultiplier: 0,
            nftBaseMultiplier: nftBaseMultiplier,
            nftPremiumMultiplier: nftPremiumMultiplier,
            delegateRegistry: address(0x1), 
            marketPlace: marketPlace,
            operatorRole: operatorRole,
            defaultAdmin: defaultAdminRole
        });

        vm.expectRevert(IMonStakingErrors.MonStaking__InvalidTokenBaseMultiplier.selector);
        new MonStaking(config);
    }

    function testConstructorRevertInvalidNftBaseMultiplier() public {
        MonStaking.Config memory config = MonStaking.Config({
            endpoint: endpoint,
            delegated: delegated,
            premiumDuration: premiumDuration,
            monsterToken: monsterTokenAddress,
            nftToken: monERC721Address,
            tokenBaseMultiplier: tokenBaseMultiplier,
            tokenPremiumMultiplier: tokenPremiumMultiplier,
            nftBaseMultiplier: 0,
            nftPremiumMultiplier: nftPremiumMultiplier,
            delegateRegistry: address(0x1), 
            marketPlace: marketPlace,
            operatorRole: operatorRole,
            defaultAdmin: defaultAdminRole
        });

        vm.expectRevert(IMonStakingErrors.MonStaking__InvalidNftBaseMultiplier.selector);
        new MonStaking(config);
    }

    function testConstructorRevertInvalidNftPremiumMultiplier() public {
        MonStaking.Config memory config = MonStaking.Config({
            endpoint: endpoint,
            delegated: delegated,
            premiumDuration: premiumDuration,
            monsterToken: monsterTokenAddress,
            nftToken: monERC721Address,
            tokenBaseMultiplier: tokenBaseMultiplier,
            tokenPremiumMultiplier: tokenPremiumMultiplier,
            nftBaseMultiplier: nftBaseMultiplier,
            nftPremiumMultiplier: 0,
            delegateRegistry: address(0x1), 
            marketPlace: marketPlace,
            operatorRole: operatorRole,
            defaultAdmin: defaultAdminRole
        });

        vm.expectRevert(IMonStakingErrors.MonStaking__InvalidNftBaseMultiplier.selector);
        new MonStaking(config);
    }

    function testConstructorRevertInvalidTokenDecimals() public {
        // Deploy a mock token with zero decimals
        MockMonsterToken zeroDecimalsToken = new MockMonsterToken();
        zeroDecimalsToken.setDecimals(0);

        MonStaking.Config memory config = MonStaking.Config({
            endpoint: endpoint,
            delegated: delegated,
            premiumDuration: premiumDuration,
            monsterToken: address(zeroDecimalsToken),
            nftToken: monERC721Address,
            tokenBaseMultiplier: tokenBaseMultiplier,
            tokenPremiumMultiplier: tokenPremiumMultiplier,
            nftBaseMultiplier: nftBaseMultiplier,
            nftPremiumMultiplier: nftPremiumMultiplier,
            delegateRegistry: address(0x1), 
            marketPlace: marketPlace,
            operatorRole: operatorRole,
            defaultAdmin: defaultAdminRole
        });

        vm.expectRevert(IMonStakingErrors.MonStaking__InvalidTokenDecimals.selector);
        new MonStaking(config);
    }
}