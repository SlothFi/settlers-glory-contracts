// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {MockERC721Receiver} from "./MockERC721Receiver.t.sol";

/**
 * @title MockRevertOnReceiveContract
 * @dev Contract that reverts when it receives ETH
 */
contract MockRevertOnReceiveContract is MockERC721Receiver{

    // Fallback function that reverts when receiving ETH
    fallback() external payable {
        revert("MockRevertOnReceiveContract: Cannot receive ETH");
    }

    // Receive function that reverts when receiving ETH
    receive() external payable {
        revert("MockRevertOnReceiveContract: Cannot receive ETH");
    }
}