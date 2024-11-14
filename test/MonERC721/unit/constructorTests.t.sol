// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {MonERC721TestBase} from "../MonERC721TestBase.t.sol";
import {MonERC721} from "../../../src/MonERC721.sol";

/**
 * @title ConstructorTests
 * @dev Tests for the constructor of MonERC721
 */
contract ConstructorTests is MonERC721TestBase {

    function setUp() public override {
        super.setUp();
    }

    function testDeploySuccess() public {
        MonERC721 monERC721 = new MonERC721(
            name,
            symbol,
            owner,
            maxSupply,
            priceInNativeToken,
            priceInMonsterToken,
            monsterTokenAddress,
            baseURI,
            fundsWallet
        );

        assertEq(monERC721.maxSupply(), maxSupply);
        assertEq(monERC721.priceInNativeToken(), priceInNativeToken);
        assertEq(monERC721.priceInMonsterToken(), priceInMonsterToken);
        assertEq(monERC721.monsterToken(), monsterTokenAddress);
        assertEq(monERC721.baseUri(), baseURI);
        assertEq(monERC721.fundsWallet(), fundsWallet);
    }

    function testDeployMaxSupplyZero() public {
        vm.expectRevert(MonERC721.MonERC721__InvalidMaxSupply.selector);
        new MonERC721(
            name,
            symbol,
            owner,
            0,
            priceInNativeToken,
            priceInMonsterToken,
            monsterTokenAddress,
            baseURI,
            fundsWallet
        );
    }

    function testDeployPriceNativeZero() public {
        vm.expectRevert(MonERC721.MonERC721__InvalidPriceInNativeToken.selector);
        new MonERC721(
            name,
            symbol,
            owner,
            maxSupply,
            0,
            priceInMonsterToken,
            monsterTokenAddress,
            baseURI,
            fundsWallet
        );
    }

    function testDeployPriceMonsterZero() public {
        vm.expectRevert(MonERC721.MonERC721__InvalidPriceInMonsterToken.selector);
        new MonERC721(
            name,
            symbol,
            owner,
            maxSupply,
            priceInNativeToken,
            0,
            monsterTokenAddress,
            baseURI,
            fundsWallet
        );
    }

    function testDeployMonsterTokenZero() public {
        vm.expectRevert(MonERC721.MonERC721__InvalidMonsterToken.selector);
        new MonERC721(
            name,
            symbol,
            owner,
            maxSupply,
            priceInNativeToken,
            priceInMonsterToken,
            address(0),
            baseURI,
            fundsWallet
        );
    }

    function testDeployFundsWalletZero() public {
        vm.expectRevert(MonERC721.MonERC721__InvalidWallet.selector);
        new MonERC721(
            name,
            symbol,
            owner,
            maxSupply,
            priceInNativeToken,
            priceInMonsterToken,
            monsterTokenAddress,
            baseURI,
            address(0)
        );
    }

    function testDeployBaseUriEmpty() public {
        vm.expectRevert(MonERC721.MonERC721__InvalidBaseUri.selector);
        new MonERC721(
            name,
            symbol,
            owner,
            maxSupply,
            priceInNativeToken,
            priceInMonsterToken,
            monsterTokenAddress,
            "",
            fundsWallet
        );
    }
}