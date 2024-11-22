// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {MonERC721TestBase} from "../MonERC721TestBase.t.sol";
import {MonERC721} from "../../../src/MonERC721.sol";

/**
 * @title GetTokenUriTest
 * @dev Test the getTokenUri function
 */
contract GetTokenUriTest is MonERC721TestBase {
    function setUp() public override {
        super.setUp();
    }

    /**
     * @dev Test the getTokenUri function
     * @notice Assrts that the token URI is correct
     */
    function test_getTokenUri() public {
        vm.startPrank(alice);
        monERC721.mintWithNativeToken{value: PRICE_IN_NATIVE_TOKEN}();
        vm.stopPrank();
        string memory uri = monERC721.tokenURI(1);
        assertEq(uri, "https://example.com/1");
    }
}
