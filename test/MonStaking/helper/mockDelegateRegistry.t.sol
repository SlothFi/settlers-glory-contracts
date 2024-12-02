// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.13;

import {IDelegateRegistry} from "../../../src/interfaces/IDelegateRegistry.sol";

/**
 * @title MockDelegateRegistry
 * @dev Mock contract for DelegateRegistry with the delegate functions
 */
contract MockDelegateRegistry is IDelegateRegistry {
    function multicall(bytes[] calldata data) external payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
    }

    function delegateAll(address to, bytes32 rights, bool enable) external payable override returns (bytes32) {
        return keccak256(abi.encodePacked(to, rights, enable));
    }

    function delegateContract(address to, address contract_, bytes32 rights, bool enable)
        external
        payable
        override
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(to, contract_, rights, enable));
    }

    function delegateERC721(address to, address contract_, uint256 tokenId, bytes32 rights, bool enable)
        external
        payable
        override
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(to, contract_, tokenId, rights, enable));
    }

    function delegateERC20(address to, address contract_, bytes32 rights, uint256 amount)
        external
        payable
        override
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(to, contract_, rights, amount));
    }

    function delegateERC1155(address to, address contract_, uint256 tokenId, bytes32 rights, uint256 amount)
        external
        payable
        override
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(to, contract_, tokenId, rights, amount));
    }

    function checkDelegateForAll(address to, address from, bytes32 rights) external view override returns (bool) {
        return true;
    }

    function checkDelegateForContract(address to, address from, address contract_, bytes32 rights)
        external
        view
        override
        returns (bool)
    {
        return true;
    }

    function checkDelegateForERC721(address to, address from, address contract_, uint256 tokenId, bytes32 rights)
        external
        view
        override
        returns (bool)
    {
        return true;
    }

    function checkDelegateForERC20(address to, address from, address contract_, bytes32 rights)
        external
        view
        override
        returns (uint256)
    {
        return 0;
    }

    function checkDelegateForERC1155(address to, address from, address contract_, uint256 tokenId, bytes32 rights)
        external
        view
        override
        returns (uint256)
    {
        return 0;
    }

    function getIncomingDelegations(address to) external view override returns (Delegation[] memory delegations) {
        delegations = new Delegation[](0);
    }

    function getOutgoingDelegations(address from) external view override returns (Delegation[] memory delegations) {
        delegations = new Delegation[](0);
    }

    function getIncomingDelegationHashes(address to) external view override returns (bytes32[] memory delegationHashes) {
        delegationHashes = new bytes32[](0);
    }

    function getOutgoingDelegationHashes(address from) external view override returns (bytes32[] memory delegationHashes) {
        delegationHashes = new bytes32[](0);
    }

    function getDelegationsFromHashes(bytes32[] calldata delegationHashes)
        external
        view
        override
        returns (Delegation[] memory delegations)
    {
        delegations = new Delegation[](delegationHashes.length);
    }

    function readSlot(bytes32 location) external view override returns (bytes32) {
        return bytes32(0);
    }

    function readSlots(bytes32[] calldata locations) external view override returns (bytes32[] memory) {
        return new bytes32[](locations.length);
    }
}