// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import { MessagingParams, MessagingFee, MessagingReceipt } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

/**
 * @title MockLayerZeroEndpointV2
 * @dev Mock contract for LayerZeroEndpointV2 with the setDelegate function
 */
contract MockLayerZeroEndpointV2{
    address public delegate;

    /**
     * @notice Sets the delegate address
     * @param _delegate The address of the delegate
     */
    function setDelegate(address _delegate) external{
        delegate = _delegate;
    }

    /**
     * @notice Mock quote function to calculate the messaging fee
     * @param _params The messaging parameters
     * @param _sender The address of the sender
     * @return fee The calculated MessagingFee
     */
    function quote(MessagingParams calldata _params, address _sender) external pure returns (MessagingFee memory fee) {
        fee = MessagingFee({
            nativeFee: 0,
            lzTokenFee: 0
        });
    }

    function send(MessagingParams calldata _params, address _refundAddress) external payable returns (MessagingReceipt memory){
        return MessagingReceipt({
            guid: bytes32(0),
            nonce: 0,
            fee: MessagingFee({
                nativeFee: 0,
                lzTokenFee: 0
            })
        });
    }
}