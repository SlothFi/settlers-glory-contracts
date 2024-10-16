// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

/**
 * @title IMonERC721
 * @dev Interface for MonERC721 contract
 */
interface IMonERC721 {
    /**
     * @dev Returns the max supply of tokens
     */
    function maxSupply() external view returns (uint256);

    /**
     * @dev Returns the price of the token in native token
     */
    function priceInNativeToken() external view returns (uint256);

    /**
     * @dev Returns the price of the token in monster token
     */
    function priceInMonsterToken() external view returns (uint256);

    /**
     * @dev Returns the address of the native token
     */
    function monsterToken() external view returns (address);

    /**
     * @dev Returns the address of the monster token
     */
    function fundsWallet() external view returns (address);

    /**
     * @dev Returns the base uri of the token
     */
    function baseUri() external view returns (string memory);

    /**
     * @dev Returns the current token id
     */
    function currentTokenId() external view returns (uint256);

    /**
     * @dev Mint a token with native token
     */
    function mintWithNativeToken() external payable;

    /**
     * @dev Mint a token with monster token
     */
    function mintWithMonsterToken() external;

    /**
     * @dev Set the address of the funds wallet
     */
    function setFundsWallet(address _fundsWallet) external;

    /**
     * @dev Returns the balance of the native token
     */
    function setBaseUri(string memory _baseUri) external;

    /**
     * @dev Withdraw native tokens
     */
    function withdrawNativeTokens(uint256 _amount) external;

    /**
     * @dev Withdraw monster tokens
     */
    function withdrawMonsterTokens(uint256 _amount) external;
}