// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title MockERC721Receiver
 * @dev Mock contract to test ERC721 transfers to a contract
 */
contract MockERC721Receiver is IERC721Receiver {

    event Received(address operator, address from, uint256 tokenId, bytes data, uint256 gas);

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        emit Received(operator, from, tokenId, data, gasleft());
        return this.onERC721Received.selector;
    }
}