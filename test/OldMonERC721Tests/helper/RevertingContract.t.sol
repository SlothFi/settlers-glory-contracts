// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {IMonERC721} from "../../../src/interfaces/IMonERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title RevertingContract
 * @dev A contract that reverts on native transfer
 * @dev Used for testing purposes
 */
contract RevertingContract is IERC721Receiver {
    IMonERC721 public immutable monERC721;
    address public immutable owner;
    uint256 public immutable nativePrice;

    constructor(address _monERC721, uint256 _nativePrice, address _owner) payable {
        monERC721 = IMonERC721(_monERC721);
        owner = _owner;
        nativePrice = _nativePrice;
    }

    function mint() external {
        monERC721.mintWithNativeToken{value: nativePrice * 2}();
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
