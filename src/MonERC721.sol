// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IMonERC721} from "./interfaces/IMonERC721.sol";

/**
 * @title MonERC721
 * @dev This contract implements an ERC721 token with a fixed supply and a fixed price to mint a token.
 * The token can be minted using either native tokens or a different ERC20 token.
 * The contract owner can withdraw the native tokens and the ERC20 tokens to the fund receiver wallet.
 */
contract MonERC721 is ERC721, Ownable2Step, IMonERC721 {
    using SafeERC20 for IERC20;

    //////////////////////////////////////////////////
    ///////////// ERRORS /////////////////////////////
    //////////////////////////////////////////////////

    error MonERC721__InvalidMaxSupply(); // It is thrown when the maximum supply is invalid
    error MonERC721__InvalidPriceInNativeToken(); // It is thrown when the price to mint a token in native tokens is zero
    error MonERC721__InvalidPriceInMonsterToken(); // It is thrown when the price to mint a token in monster tokens is zero
    error MonERC721__InvalidMonsterToken(); // It is thrown when the monster token address is address(0)
    error MonERC721__NotEnoughNativeTokens(); // It is thrown when a user attempts to mint a token with less native tokens than the price
    error MonERC721__MaxSupplyReached(); // It is thrown when the maximum supply is reached and no more tokens can be minted
    error MonERC721__InvalidWallet(); // It is thrown when the funds wallet address is address(0)
    error MonERC721__InvalidBaseUri(); // It is thrown when the base URI is empty
    error MonERC721__NativeTransferFailed(); // It is thrown when the native tokens transfer fails
    error MonERC721__NotEnoughMonterTokens(); // It is thrown when a user attempts to mint a token with less monster tokens than the price
    error MonERC721__MonsterTransferFailed(); // It is thrown when the monster tokens transfer fails
    error MonERC721__NoZeroAmount(); // It is thrown when the amount to withdraw is zero

    //////////////////////////////////////////////////
    ///////////// EVENTS /////////////////////////////
    //////////////////////////////////////////////////

    /**
     * @dev  It is emitted when a token is minted
     * @param to The address of the token owner
     * @param tokenId The ID of the token
     */
    event TokenMinted(address indexed to, uint256 indexed tokenId);

    /**
     * @dev  It is emitted when the funds wallet is changed
     * @param oldWallet The old wallet address
     * @param newWallet The new wallet address
     */
    event FundsWalletChanged(address indexed oldWallet, address indexed newWallet);

    /**
     * @dev  It is emitted when the base URI is changed
     * @param oldUri The old base URI
     * @param newUri The new base URI
     */
    event BaseUriChanged(string indexed oldUri, string indexed newUri);

    /**
     * @dev  It is emitted when the native tokens are withdrawn
     * @param to The address of the receiver
     * @param amount The amount of native tokens withdrawn
     */
    event NativeTokensWithdrawn(address indexed to, uint256 indexed amount);

    /**
     * @dev  It is emitted when the monster tokens are withdrawn
     * @param to The address of the receiver
     * @param amount The amount of monster tokens withdrawn
     */
    event MonsterTokensWithdrawn(address indexed to, uint256 indexed amount);

    //////////////////////////////////////////////////
    ///////////// VARIABLES //////////////////////////
    //////////////////////////////////////////////////

    // Immutable variables
    uint256 public immutable maxSupply; // The maximum supply of the token
    uint256 public immutable priceInNativeToken; // The price to mint a token in native tokens
    uint256 public immutable priceInMonsterToken; // The price to mint a token in monster tokens
    address public immutable monsterToken; // The address of the monster token

    // State variables
    string public baseUri; // The base URI for the token metadata
    uint256 public currentTokenId; // The current token ID minted
    address public fundsWallet; // The wallet to receive the funds

    //////////////////////////////////////////////////
    ///////////// FUNCTIONS //////////////////////////
    //////////////////////////////////////////////////

    /**
     * @dev Constructor to initialize the contract with the following parameters
     * @param _name The name of the token
     * @param _symbol The symbol of the token
     * @param _owner The owner of the contract
     * @param _maxSupply The maximum supply of the token
     * @param _priceInNativeToken The price to mint a token in native tokens
     * @param _priceInMonsterToken The price to mint a token in monster tokens
     * @param _monsterToken The address of the monster token
     * @param _baseUri The base URI for the token metadata
     * @param _fundsWallet The wallet to receive the funds
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _owner,
        uint256 _maxSupply,
        uint256 _priceInNativeToken,
        uint256 _priceInMonsterToken,
        address _monsterToken,
        string memory _baseUri,
        address _fundsWallet
    ) ERC721(_name, _symbol) Ownable(_owner) {
        if (_maxSupply == 0) revert MonERC721__InvalidMaxSupply();
        if (_priceInNativeToken == 0) {
            revert MonERC721__InvalidPriceInNativeToken();
        }
        if (_priceInMonsterToken == 0) {
            revert MonERC721__InvalidPriceInMonsterToken();
        }
        if (_monsterToken == address(0)) {
            revert MonERC721__InvalidMonsterToken();
        }
        if (_fundsWallet == address(0)) revert MonERC721__InvalidWallet();
        if (bytes(_baseUri).length == 0) revert MonERC721__InvalidBaseUri();

        maxSupply = _maxSupply;
        priceInNativeToken = _priceInNativeToken;
        priceInMonsterToken = _priceInMonsterToken;
        monsterToken = _monsterToken;
        baseUri = _baseUri;
        fundsWallet = _fundsWallet;
    }

    /**
     * @dev Mint a token using native tokens
     * @notice If the user sends more native tokens than the price, the contract will refund the extra amount
     */
    function mintWithNativeToken() external payable {
        if (msg.value < priceInNativeToken) {
            revert MonERC721__NotEnoughNativeTokens();
        }
        if (currentTokenId == maxSupply) revert MonERC721__MaxSupplyReached();
        _safeMint(msg.sender, ++currentTokenId);

        if (msg.value > priceInNativeToken) {
            (bool success,) = payable(msg.sender).call{value: msg.value - priceInNativeToken}("");
            if (!success) revert MonERC721__NativeTransferFailed();
        }

        emit TokenMinted(msg.sender, currentTokenId);
    }

    /**
     * @dev Mint a token using monster tokens
     */
    function mintWithMonsterToken() external {
        if (currentTokenId == maxSupply) revert MonERC721__MaxSupplyReached();
        _safeMint(msg.sender, ++currentTokenId);

        IERC20(monsterToken).safeTransferFrom(msg.sender, address(this), priceInMonsterToken);

        emit TokenMinted(msg.sender, currentTokenId);
    }

    /**
     * @dev Set the wallet to receive the funds
     * @param _fundsWallet The new wallet address
     */
    function setFundsWallet(address _fundsWallet) external onlyOwner {
        if (_fundsWallet == address(0)) revert MonERC721__InvalidWallet();
        address oldWallet = fundsWallet;
        fundsWallet = _fundsWallet;

        emit FundsWalletChanged(oldWallet, _fundsWallet);
    }

    /**
     * @dev Set the base URI for the token metadata
     * @param _baseUri The new base URI
     */
    function setBaseUri(string memory _baseUri) external onlyOwner {
        if (bytes(_baseUri).length == 0) revert MonERC721__InvalidBaseUri();
        string memory oldUri = baseUri;
        baseUri = _baseUri;

        emit BaseUriChanged(oldUri, _baseUri);
    }

    /**
     * @dev Withdraw the native tokens from the contract
     * @param _amount The amount of native tokens to withdraw
     * @notice The owner can withdraw all the native tokens by passing `type(uint256).max` as the amount
     */
    function withdrawNativeTokens(uint256 _amount) external onlyOwner {
        if (_amount == 0) revert MonERC721__NoZeroAmount();

        uint256 balance = address(this).balance;
        bool isMax = _amount == type(uint256).max;

        if (_amount > balance && !isMax) {
            revert MonERC721__NotEnoughNativeTokens();
        }
        (bool success,) = payable(fundsWallet).call{value: isMax ? balance : _amount}("");
        if (!success) revert MonERC721__NativeTransferFailed();

        emit NativeTokensWithdrawn(fundsWallet, isMax ? balance : _amount);
    }

    /**
     * @dev Withdraw the monster tokens from the contract
     * @param _amount The amount of monster tokens to withdraw
     * @notice The owner can withdraw all the monster tokens by passing `type(uint256).max` as the amount
     */
    function withdrawMonsterTokens(uint256 _amount) external onlyOwner {
        if (_amount == 0) revert MonERC721__NoZeroAmount();

        uint256 balance = IERC20(monsterToken).balanceOf(address(this));
        bool isMax = _amount == type(uint256).max;

        if (_amount > balance && !isMax) {
            revert MonERC721__NotEnoughMonterTokens();
        }

        IERC20(monsterToken).safeTransfer(fundsWallet, isMax ? balance : _amount);

        emit MonsterTokensWithdrawn(fundsWallet, isMax ? balance : _amount);
    }

    /**
     * @dev Returns the base token URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }
}

