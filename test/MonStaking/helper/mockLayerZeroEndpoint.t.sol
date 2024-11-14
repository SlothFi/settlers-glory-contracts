// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

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
}