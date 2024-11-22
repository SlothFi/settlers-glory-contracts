// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {MonERC721TestBase} from "../MonERC721TestBase.t.sol";
import {MonERC721} from "../../../src/MonERC721.sol";

/**
 * @title SetBaseUriTest
 * @dev Test the setBaseUri function
 */
contract SetBaseUriTest is MonERC721TestBase {
    event BaseUriChanged(string indexed oldBaseUri, string indexed newBaseUri);

    function setUp() public override {
        super.setUp();
    }

    /**
     * @dev Test the setBaseUri function
     * @notice Asserts that the base URI is set correctly
     */
    function test_setBaseUri() public {
        string memory newBaseUri = "https://myapi.com/";
        vm.startPrank(owner);
        monERC721.setBaseUri(newBaseUri);
        vm.stopPrank();

        assertEq(monERC721.baseUri(), newBaseUri);
    }

    /**
     * @dev Test the setBaseUri function
     * @notice Asserts that it reverts if the caller is not the owner
     */
    function test_setBaseUri_revertsIfNotOwner() public {
        vm.expectRevert();
        vm.startPrank(alice);
        monERC721.setBaseUri("https://myapi.com/");
        vm.stopPrank();
    }

    /**
     * @dev Test the setBaseUri function
     * @notice Asserts that it reverts if the base URI is empty
     */
    function test_setBaseUri_revertsIfBaseUriIsEmpty() public {
        vm.expectRevert(MonERC721.MonERC721__InvalidBaseUri.selector);
        vm.startPrank(owner);
        monERC721.setBaseUri("");
        vm.stopPrank();
    }

    /**
     * @dev Test the setBaseUri function
     * @notice Asserts that it emits an event
     */
    function test_setBaseUri_emitsAnEvent() public {
        string memory oldBaseUri = monERC721.baseUri();
        string memory newBaseUri = "https://myapi.com/";
        vm.expectEmit(true, true, false, false);
        emit BaseUriChanged(oldBaseUri, newBaseUri);
        vm.startPrank(owner);
        monERC721.setBaseUri(newBaseUri);
        vm.stopPrank();
    }
}
