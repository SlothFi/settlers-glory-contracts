// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {OApp, Origin, MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol"; // This needs to be changed to ReentrancyGuard when deploying on AVAX
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IMonStaking} from "./interfaces/IMonStaking.sol";
import {IMonStakingErrors} from "./interfaces/errors/IMonStakingErrors.sol";
import {IMonStakingEvents} from "./interfaces/events/IMonStakingEvents.sol";

import {IMonERC721} from "./interfaces/IMonERC721.sol";
import {IDelegateRegistry} from "./interfaces/IDelegateRegistry.sol";

import {LiquidStakedMonster} from "./LiquidStakedMonster.sol";

/**
* @title MonStaking
* @notice This contract is used for staking and unstaking of tokens and NFTs
* @dev It implements the OApp for LayerZero in other to communicate with other chains
* @dev It is the owner of the LiquidStakedMonster contract and is able to mint and burn tokens in that contract
* @dev It implements IERC721Receiver to be able to receive NFTs
*/
contract MonStaking is OApp, IERC721Receiver, ReentrancyGuardTransient, IMonStaking, IMonStakingErrors, IMonStakingEvents  {

    using SafeERC20 for IERC20;

    /// @notice Enum for the multipliers: TOKEN_BASE, TOKEN_PREMIUM, NFT_BASE, NFT_PREMIUM
    enum Multipliers {
        TOKEN_BASE,
        TOKEN_PREMIUM,
        NFT_BASE,
        NFT_PREMIUM
    }

    /// @notice Struct for the UserUnstakeRequest - This struct is updated when a user completely unstakes after being in premium
    /// @dev It is done to avoid the user being able to take advantage intechain communication latency
    /// @dev The max amount of NFT transferable in one tx is 20
    /// @param tokenAmount - The amount of tokens the user has staked
    /// @param nftAmount - The amount of NFTs the user has staked
    /// @param requestTimestamp - The timestamp when the request was made
    struct UserUnstakeRequest {
        uint256 tokenAmount;
        uint256 nftAmount;
        uint256 requestTimestamp;
    }

    struct Config {
        address endpoint;
        address delegated;
        uint256 premiumDuration;
        address monsterToken;
        address nftToken;
        uint256 tokenBaseMultiplier;
        uint256 tokenPremiumMultiplier;
        uint256 nftBaseMultiplier;
        uint256 nftPremiumMultiplier;
        address delegateRegistry;
        address marketPlace;
        address operatorRole;
        address defaultAdmin;
    }
    
    /// @dev Basis points - 100% = 10_000
    uint256 public constant BPS = 10_000;

    /// @dev 1e6 points = 1 point - It is enforced to avoid precision losses
    uint256 public constant POINTS_DECIMALS = 1e6;

    /// @dev The maximum amount of chains that can be supported
    uint256 public constant MAX_SUPPOERTED_CHAINS = 10;

    /// @dev The duration of the timelock when a total unstake request is made
    uint256 public constant TIME_LOCK_DURATION = 3 hours; 

    /// @dev The maximum amount of NFTs that can be batch withdrawn
    uint256 public constant MAX_BATCH_NFT_WITHDRAW = 20;

    /// @dev It is the group cardinalidity for the bitmap
    /// @dev Chain ids will be wrapped around this number
    /// @notice Number collision is possible but has been checked and is not a problem 
    /// @dev Chains are ETH, ARB and AVAX
    uint8 public constant BITMAP_BOUND = type(uint8).max;

    /// @dev It stores the time in which the contract has been created
    uint256 public immutable i_creationTimestamp;

    /// @dev It stores the duration of the premium staking window - if users stake after this time they will be base
    uint256 public immutable i_premiumDuration;

    /// @dev It stores the time in which the premium staking window ends
    uint256 public immutable i_endPremiumTimestamp;

    /// @dev It stores the address of the MonsterToken
    address public immutable i_monsterToken;

    /// @dev It stores the decimals of the MonsterToken
    uint256 public immutable i_monsterTokenDecimals;

    /// @dev It stores the address of the LiquidStakedMonster contract
    address public immutable i_lsToken;

    /// @dev It stores the address of the NFT token
    address public immutable i_nftToken;

    /// @dev It stores the max supply of the NFT token
    uint256 public immutable i_nftMaxSupply;

    /// @dev It stores the address of the DelegateRegistry
    /// @dev It is used to enable users to prove ownership of their nfts while staked
    IDelegateRegistry public immutable i_delegateRegistry;

    /// @dev It stores the token base multiplier
    uint256 public s_tokenBaseMultiplier;

    /// @dev It stores the token premium multiplier
    uint256 public s_tokenPremiumMultiplier;

    /// @dev It stores the NFT base multiplier
    uint256 public s_nftBaseMultiplier;

    /// @dev It stores the NFT premium multiplier
    uint256 public s_nftPremiumMultiplier;

    /// @dev It stores the user's staked NFT amount
    mapping(address user => uint256 nftAmount) public s_userNftAmount;

    /// @dev It stores the owner of the NFT
    mapping(uint256 tokenId => address owner) public s_nftOwner;

    /// @dev It stores the user's points
    mapping(address user => uint256 points) public s_userPoints;

    /// @dev It stores the user's staked token amount
    mapping(address user => uint256 stakedTokenAmount) public s_userStakedTokenAmount;

    /// @dev It stores the user's last updated timestamp
    /// @dev It updates each time a user's balance state is updated
    mapping(address user => uint256 lastUpdatedTimestamp) public s_userLastUpdatedTimestamp;

    /// @dev It stores the other chain's staking contract address
    /// @notice it is in bytes32 because LayerZero requires so
    mapping(uint32 chainId => bytes32 otherChainStaking) public s_otherChainStakingContract;

    /// @dev It stores the supported chains
    uint32[] public s_supportedChains;

    /// @dev It stores the index of the chain in the supported chains array
    /// @dev It is made to grant read access in o(1)
    mapping(uint32 chainId => uint256 index) public s_chainIndex;

    /// @dev It stores the user's premium state on other chains
    /// @dev It is a bitmap where each bit represents a chain
    /// @dev It is made to optimise read access in o(1)
    mapping(address user => uint256 bitmap) public s_isUserPremiumOnOtherChains;

    /// @dev It is designed to make chain eids potential collisions over the BITMAP_BOUND cardinality possible
    /// @dev If a collision happens this mapping will be updated
    mapping(address user => mapping(uint256 bitmapChainIndex => uint256 collisions)) public s_userChainIndexCollisions;

    /// @dev It stores the user's premium state
    /// @dev It stays true if the user is premium in at least one chain
    mapping(address user => bool isPremium) public s_isUserPremium;

    /// @dev It stores the user's unstake request when total unstaking is performed
    mapping(address user => UserUnstakeRequest unstakeRequest) public s_userUnstakeRequest;

    /// @dev It stores the address of the proposed new owner
    address public s_newProposedOwner;

    /**
    * @notice Modifier to check if the msg.sender is the LiquidStakedMonster contract
    * @dev It is used to restrict the access to the LiquidStakedMonster contract 
    * @dev It is used in the updateStakingState() function
    */
    modifier onlyLSMContract() {
        if (msg.sender != i_lsToken) revert MonStaking__NotLSMContract();
        _;
    }

    /**
    * @notice Modifier to check if the timelock has passed
    * @dev It is used when a user wants to claim the unstaked assets
    */
    modifier ifTimelockAllows() {
        if (s_userUnstakeRequest[msg.sender].requestTimestamp + TIME_LOCK_DURATION > block.timestamp) {
            revert MonStaking__TimelockNotPassed();
        }
        _;
    }

    /**
    * @notice Modifier to check if the msg.sender is the proposed owner
    * @dev It is used when the ownership is claimed
    */
    modifier onlyProposedOwner() {
        if (msg.sender != s_newProposedOwner) revert MonStaking__NotProposedOwner();
        _;
    }

    /**
    * @notice Construcor - It initializes the contract
    * @dev It deploys the LiquidStakedMonster contract and it is its owner
    */
    constructor(Config memory config) OApp(config.endpoint, config.delegated) Ownable(config.delegated) 
    {
        if (
            config.monsterToken == address(0) || 
            config.nftToken == address(0) ||
            config.delegateRegistry == address(0)
        ) revert MonStaking__ZeroAddress();
        if (config.premiumDuration == 0) revert MonStaking__ZeroAmount();
        if (config.tokenBaseMultiplier == 0 || config.tokenBaseMultiplier >= config.tokenPremiumMultiplier) {
            revert MonStaking__InvalidTokenBaseMultiplier();
        }
        if (config.tokenPremiumMultiplier == 0) revert MonStaking__InvalidTokenPremiumMultiplier();
        if (config.nftBaseMultiplier == 0 || config.nftBaseMultiplier >= config.nftPremiumMultiplier) {
            revert MonStaking__InvalidNftBaseMultiplier();
        }
        if (config.nftPremiumMultiplier == 0) revert MonStaking__InvalidNftPremiumMultiplier();

        i_creationTimestamp = block.timestamp;
        i_premiumDuration = config.premiumDuration;
        i_endPremiumTimestamp = i_creationTimestamp + config.premiumDuration;
        i_monsterToken = config.monsterToken;
        i_monsterTokenDecimals = IERC20Metadata(config.monsterToken).decimals();
        if (i_monsterTokenDecimals == 0) revert MonStaking__InvalidTokenDecimals();
        i_nftToken = config.nftToken;
        i_nftMaxSupply = IMonERC721(config.nftToken).maxSupply();
        i_delegateRegistry = IDelegateRegistry(config.delegateRegistry);

        s_tokenBaseMultiplier = config.tokenBaseMultiplier;
        s_tokenPremiumMultiplier = config.tokenPremiumMultiplier;
        s_nftBaseMultiplier = config.nftBaseMultiplier;
        s_nftPremiumMultiplier = config.nftPremiumMultiplier;

        i_lsToken = address(new LiquidStakedMonster(config.operatorRole, config.defaultAdmin, config.marketPlace));
    }

    /**
    * @notice It is used to staked Monster tokens
    * @notice It mints LiquidStakedMonster tokens to the user which are 1:1 ratio with the staked tokens
    * @dev It is payable becuase if the user is premium it will need to call other chains
    * @param _amount - The amount of tokens to be staked
    * @dev It emits a TokensStaked event
    */
    function stakeTokens(uint256 _amount) external payable nonReentrant {

        if (_amount == 0) revert MonStaking__ZeroAmount();

        _updateUserState(msg.sender);

        s_userStakedTokenAmount[msg.sender] += _amount;
        
        if (!s_isUserPremium[msg.sender] && block.timestamp <= i_endPremiumTimestamp) {
            s_isUserPremium[msg.sender] = true;
            _updateOtherChains(msg.sender, true);
        }

        IERC20(i_monsterToken).safeTransferFrom(msg.sender, address(this), _amount);

        LiquidStakedMonster(i_lsToken).mint(msg.sender, _amount);

        emit TokensStaked(msg.sender, _amount);
    }

    /**
    * @notice It is used to stake NFTs
    * @dev It is payable becuase if the user is premium it will need to call other chains
    * @param _tokenId - The id of the NFT to be staked
    * @dev It emits a NftStaked event
    * @dev It enables as delegated of the nft the msg.sender
    */
    function stakeNft(uint256 _tokenId) external payable nonReentrant {

        if(_tokenId == 0 || _tokenId > i_nftMaxSupply) revert MonStaking__InvalidTokenId();

        _updateUserState(msg.sender);

        s_userNftAmount[msg.sender] += 1;
        s_nftOwner[_tokenId] = msg.sender;

        if (!s_isUserPremium[msg.sender] && block.timestamp <= i_endPremiumTimestamp){
            s_isUserPremium[msg.sender] = true;
            _updateOtherChains(msg.sender, true);
        }

        IERC721(i_nftToken).safeTransferFrom(msg.sender, address(this), _tokenId);

        _toggleNftDelegation(msg.sender, _tokenId, true);

        emit NftStaked(msg.sender, _tokenId);
    }

    /**
    * @notice It is used to unstake tokens
    * @notice It burns the LiquidStakedMonster tokens and sends the staked tokens back to the user
    * @notice It will fail if user tries to unstake more tokens than the LiquidStakedMonster tokens he has
    * @notice Can be used to totally unstake only if user is not premium
    * @notice If user is premium and  is totally unstaking the function will revert
    * @param _amount - The amount of tokens to be unstaked
    * @dev It emits a TokensUnstaked event
    */
    function unstakeTokens(uint256 _amount) external nonReentrant {

        uint256 userTokenBalance = s_userStakedTokenAmount[msg.sender];

        if (_amount == 0) revert MonStaking__ZeroAmount();
        if (_amount > userTokenBalance) revert MonStaking__NotEnoughMonsterTokens();
        if (_amount == userTokenBalance && s_userNftAmount[msg.sender] == 0 && s_isUserPremium[msg.sender]) revert MonStaking__CannotTotallyUnstake();

        _updateUserState(msg.sender);
        
        s_userStakedTokenAmount[msg.sender] -= _amount;

        if(s_userStakedTokenAmount[msg.sender] == 0 && s_userNftAmount[msg.sender] == 0) {
            _clearUserTimeInfo(msg.sender);
        }

        IERC20(i_monsterToken).safeTransfer(msg.sender, _amount);

        LiquidStakedMonster(i_lsToken).burn(msg.sender, _amount);

        emit TokensUnstaked(msg.sender, _amount);
    }

    /**
    * @notice It is used to unstake nfts
    * @notice It will fail if user tries to unstake more nfts than he has
    * @notice Can be used to totally unstake only if user is not premium
    * @notice If user is premium and  is totally unstaking the function will revert
    * @param _tokenId - The id of the NFT to be unstaked
    * @dev It emits a NftStaked event
    * @dev It disables as delegated of the nft the msg.sender
    */
    function unstakeNft(uint256 _tokenId) external nonReentrant {

        uint256 userNftBalance = s_userNftAmount[msg.sender];

        if(_tokenId == 0 || _tokenId > i_nftMaxSupply) revert MonStaking__InvalidTokenId();
        if(userNftBalance == 0) revert MonStaking__ZeroAmount();
        if(userNftBalance == 1 && s_userStakedTokenAmount[msg.sender] == 0 && s_isUserPremium[msg.sender]) revert MonStaking__CannotTotallyUnstake();
        if(s_nftOwner[_tokenId] != msg.sender) revert MonStaking__NotNftOwner();

        _updateUserState(msg.sender);

        s_userNftAmount[msg.sender] -= 1;
        delete s_nftOwner[_tokenId];

        if(s_userStakedTokenAmount[msg.sender] == 0 && s_userNftAmount[msg.sender] == 0) {
            _clearUserTimeInfo(msg.sender);
        }

        IERC721(i_nftToken).safeTransferFrom(address(this), msg.sender, _tokenId);

        _toggleNftDelegation(msg.sender, _tokenId, false);

        emit NftUnstaked(msg.sender, _tokenId);
    }

    /**
    * @notice It is used to batch unstake nfts
    * @notice It will fail if user tries to batch unstake more nfts than MAX_BATCH_NFT_WITHDRAW
    * @notice Can be used to totally unstake only if user is not premium
    * @notice If user is premium and  is totally unstaking the function will revert
    * @param _tokenIds - The ids of the NFTs to be unstaked
    * @dev It emits a NftBatchUnstaked event
    * @dev It disables as delegated of the nfts the msg.sender
    */
    function batchUnstakeNft(uint256[] calldata _tokenIds) external nonReentrant {
        uint256 tokenIdsLength = _tokenIds.length;

        if(tokenIdsLength == 0 || tokenIdsLength > MAX_BATCH_NFT_WITHDRAW) revert MonStaking__InvalidIdArrayLength();
        if(tokenIdsLength == s_userNftAmount[msg.sender] && s_userStakedTokenAmount[msg.sender] == 0 && s_isUserPremium[msg.sender]) revert MonStaking__CannotTotallyUnstake();

        _updateUserState(msg.sender);

        s_userNftAmount[msg.sender] -= tokenIdsLength;

        if(s_userStakedTokenAmount[msg.sender] == 0 && s_userNftAmount[msg.sender] == 0) {
            _clearUserTimeInfo(msg.sender);
        }

        for(uint256 i = 0; i < tokenIdsLength; ++i){

            uint256 tokenId = _tokenIds[i];

            if(s_nftOwner[tokenId] != msg.sender) revert MonStaking__NotNftOwner();

            delete s_nftOwner[tokenId];

            IERC721(i_nftToken).safeTransferFrom(address(this), msg.sender, tokenId);

            _toggleNftDelegation(msg.sender, tokenId, false);
        }

        emit NftBatchUnstaked(_tokenIds, msg.sender);

    }

    /**
    * @notice It is used to require a total unstake if user is premium
    * @notice It will fail if user has no staked tokens or nfts
    * @notice It will fail if user is not premium
    * @notice It is payable because it needs to communicated with other chains
    * @notice It is made in other to prevent a discrepancy in intechain communication latency
    * @dev If user unstakes in chain A and loses premium he could still stake in chain B resulting premium if he does so before the interchain message arrives
    * @dev It emits a TotalUnstakeRequired event
    */
    function requireUnstakeAll() external payable nonReentrant {

        uint256 userTokenBalance = s_userStakedTokenAmount[msg.sender];
        uint256 userNftBalance =  s_userNftAmount[msg.sender];

        if(!s_isUserPremium[msg.sender]) revert MonStaking__UserNotPremium();
        if(userTokenBalance == 0 && userNftBalance == 0) revert MonStaking__ZeroAmount();//@audit-issue can't hit this because if a user is premium we cant unstake all the funds

        _updateUserState(msg.sender);

        if(!_isUserPremiumOnOtherChains(msg.sender)) s_isUserPremium[msg.sender] = false;

        s_userStakedTokenAmount[msg.sender] = 0;
        s_userNftAmount[msg.sender] = 0;

        UserUnstakeRequest memory userUnstakeRequest = s_userUnstakeRequest[msg.sender];

        // If it is a new request we create a new one else we update the existing one
        if(userUnstakeRequest.requestTimestamp == 0){
            s_userUnstakeRequest[msg.sender] = UserUnstakeRequest(userTokenBalance, userNftBalance, block.timestamp);
        }else {
            userUnstakeRequest.tokenAmount += userTokenBalance;
            userUnstakeRequest.nftAmount += userNftBalance;
            userUnstakeRequest.requestTimestamp = block.timestamp;
            s_userUnstakeRequest[msg.sender] = userUnstakeRequest;
        }

        _clearUserTimeInfo(msg.sender);

        if(userTokenBalance > 0) LiquidStakedMonster(i_lsToken).burn(msg.sender, userTokenBalance);

        _updateOtherChains(msg.sender, false);

        emit TotalUnstakeRequired(msg.sender, userTokenBalance, userNftBalance);
    }

    /**
    * @notice It is used to claim the unstaked assets
    * @notice It will fail if the timelock has not passed
    * @notice It will fail if the user has no unstaked assets
    * @param _tokenIds - The ids of the NFTs to be claimed
    * @dev It emits a UnstakedAssetsClaimed event
    * @dev The check on tokenIdsLength is made to prevent DOS if user has a very large amount of staked nfts
    */
    function claimUnstakedAssets(uint256[] calldata _tokenIds) external ifTimelockAllows nonReentrant {

        uint256 tokenIdsLength = _tokenIds.length;

        if(tokenIdsLength > MAX_BATCH_NFT_WITHDRAW) revert MonStaking__TokenIdArrayTooLong();

        UserUnstakeRequest memory userUnstakeRequest = s_userUnstakeRequest[msg.sender];

        if(userUnstakeRequest.nftAmount == 0) {
            delete s_userUnstakeRequest[msg.sender];
        }else {
            s_userUnstakeRequest[msg.sender].nftAmount -= tokenIdsLength;
            s_userUnstakeRequest[msg.sender].tokenAmount = 0;

            if(s_userUnstakeRequest[msg.sender].nftAmount == 0) delete s_userUnstakeRequest[msg.sender];
        }

        IERC20(i_monsterToken).safeTransfer(msg.sender, userUnstakeRequest.tokenAmount);

        for (uint256 i = 0; i < tokenIdsLength; i++) {
            if(s_nftOwner[_tokenIds[i]] != msg.sender) revert MonStaking__NotNftOwner();
            delete s_nftOwner[_tokenIds[i]];
            IERC721(i_nftToken).safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
            _toggleNftDelegation(msg.sender, _tokenIds[i], false);
        }

        emit UnstakedAssetsClaimed(msg.sender, userUnstakeRequest.tokenAmount, _tokenIds);
    }

    /**
    * @notice It is used to update the staking state of a user
    * @notice It is called by the LiquidStakedMonster contract
    * @notice This function is called by the LiquidStakedMonster contract when a user purchases something in the market place
    * @notice It needs to be payable because if a premium user spends all his LiquidStakedMonster tokens he will lose premium and needs to communicate with other chains
    * @param _from - The address from which the amount is taken
    * @param _to - The address to which the amount is added
    * @param _amount - The amount that is transferred
    * @dev It emits a StakingBalanceUpdated event
    */
    function updateStakingBalance(address _from, address _to, uint256 _amount) external payable onlyLSMContract {

        if (_from == address(0) || _to == address(0)) revert MonStaking__ZeroAddress();
        if (_amount == 0) revert MonStaking__ZeroAmount();

        _updateUserState(_from);
        _updateUserState(_to);

        s_userStakedTokenAmount[_from] -= _amount;
        s_userStakedTokenAmount[_to] += _amount;


        if (s_userStakedTokenAmount[_from] == 0 && s_userNftAmount[_from] == 0) {
            _clearUserTimeInfo(_from);

            if(s_isUserPremium[_from]) {
                _updateOtherChains(_from, false);

                if(!_isUserPremiumOnOtherChains(_from)) s_isUserPremium[_from] = false;
            }

        }

        emit StakingBalanceUpdated(_from, _to, _amount);
    }


    /**
    * @notice It is used to ping a new chain contract and tell them that a user is premium
    * @notice It is a function created for the case new chains are added in the future
    * @notice It is payable because the user needs to pay for the interchain communication
    * @param _chainId - The chain id of the chain that is pinged
    * @dev It emits a NewChainPinged event
    */
    function pingNewChainContract(uint32 _chainId) external payable nonReentrant {

        if (_chainId == 0) revert MonStaking__ZeroChainId();
        if (s_otherChainStakingContract[_chainId] == bytes32(0)) revert MonStaking__ChainNotSupported();
        if (_isChainPremium(s_isUserPremiumOnOtherChains[msg.sender], _chainId)) revert MonStaking__UserAlreadyPremium();
        if (!s_isUserPremium[msg.sender]) revert MonStaking__UserNotPremium();

        bytes memory message = abi.encode(msg.sender, true);

        bool payInLzToken = msg.value == 0;

        MessagingFee memory _fee = _quote(_chainId, message, "", payInLzToken);


        _lzSend(_chainId, message, "", _fee, msg.sender);

        if (!payInLzToken && msg.value > _fee.nativeFee) {
            (bool success, ) = msg.sender.call{value: msg.value - _fee.nativeFee}("");
            if (!success) revert MonStaking__TransferFailed();
        } 

        emit NewChainPinged(_chainId, msg.sender);
    }

    /**
    * @notice It is used to sync up the user point state
    * @dev It emits a PointsSynced event
    */
    function syncPoints() external {
        _updateUserState(msg.sender);

        emit PointsSynced(msg.sender, s_userPoints[msg.sender]);
    }

    /**
    * @notice It is used to set the multiplier values
    * @param _multiplierType - The type of the multiplier
    * @param _value - The new value of the multiplier
    * @dev It can be called only by the owner
    */
    function setMultiplier(Multipliers _multiplierType, uint256 _value) external onlyOwner {
        if (_value == 0) revert MonStaking__ZeroAmount();

        if (_multiplierType == Multipliers.TOKEN_BASE) {
            if (_value >= s_tokenPremiumMultiplier) revert MonStaking__InvalidTokenBaseMultiplier();

            s_tokenBaseMultiplier = _value;
            emit TokenBaseMultiplierChanged(_value);
        } else if (_multiplierType == Multipliers.TOKEN_PREMIUM) {
            if (_value <= s_tokenBaseMultiplier) revert MonStaking__InvalidTokenPremiumMultiplier();

            s_tokenPremiumMultiplier = _value;
            emit TokenPremiumMultiplierChanged(_value);
        } else if (_multiplierType == Multipliers.NFT_BASE) {
            if (_value >= s_nftPremiumMultiplier) revert MonStaking__InvalidNftBaseMultiplier();

            s_nftBaseMultiplier = _value;
            emit NftBaseMultiplierChanged(_value);
        } else if (_multiplierType == Multipliers.NFT_PREMIUM) {
            if (_value <= s_nftBaseMultiplier) revert MonStaking__InvalidNftPremiumMultiplier();

            s_nftPremiumMultiplier = _value;
            emit NftPremiumMultiplierChanged(_value);
        } else {
            revert MonStaking__InvalidMultiplierType();
        }
    }

    /**
    * @notice It is used to estimate the cost of a message
    * @param _dstEids - The destination eids
    * @param _message - The message that is sent
    * @param _extraSendOptions - The extra send options
    * @param _payInLzToken - The flag that tells if the payment is in LZ token or native tokens
    */
    function getQuote(       
        uint32[] memory _dstEids,
        bytes memory _message,
        bytes memory _extraSendOptions,
        bool _payInLzToken
    ) external view returns (MessagingFee memory totalFee){
        return _batchQuote(_dstEids, _message, _extraSendOptions, _payInLzToken);
    }

    /**
    * @notice It is used to get the potential current points of a user
    * @param _user - The user for which the points are calculated
    * @return The potential current points of the user
    */
    function getPotentialCurrentPoints(address _user) external view returns (uint256){
        uint256 lastTimestamp = s_userLastUpdatedTimestamp[_user];
        bool isPremium = s_isUserPremium[_user];
        uint256 tokenPoints = _calculateTokenPoints(s_userStakedTokenAmount[_user], lastTimestamp, block.timestamp, isPremium);
        uint256 nftPoints = _calculateNftPoints(s_userNftAmount[_user], lastTimestamp, block.timestamp, isPremium);
        return s_userPoints[_user] + tokenPoints + nftPoints;
    }

    /**
    * @notice It is used to propose a new owner in a 2 step fashion
    * @param _newOwner - The address of the new owner
    * @dev It emits a NewOwnerProposed event
    * @dev It can be called only by the owner
    */
    function proposeNewOwner(address _newOwner) external onlyOwner {
        if(_newOwner == address(0)) revert MonStaking__ZeroAddress();
        s_newProposedOwner = _newOwner;
        emit NewOwnerProposed(_newOwner);
    }

    /**
    * @notice It is used to claim the ownership
    * @dev Can be called only by the proposed owner
    * @dev It emits a OwnershipClaimed event
    */
    function claimOwnerhip() external onlyProposedOwner {
        address oldOwner = owner();

        _transferOwnership(s_newProposedOwner);

        delete s_newProposedOwner;
        emit OwnershipClaimed(msg.sender, oldOwner);
    }

    /**
    * @notice It is used to remove a supported chain
    * @param _chainId - The chain id that is removed
    * @dev It emits a ChainRemoved event
    * @dev It can be called only by the owner
    */
    function removeSupportedChain(uint32 _chainId) external onlyOwner {
        if (_chainId == 0) revert MonStaking__ZeroChainId();
        if (s_otherChainStakingContract[_chainId] == bytes32(0)) revert MonStaking__ChainNotSupported();

        _setPeer(_chainId, bytes32(0));

        emit ChainRemoved(_chainId);
    }

    /**
    * @notice It is used to batch set multiple chains
    * @notice It cannot set more than 10 chains
    * @param _chainIds - The chain ids that are enabled
    * @param _peers - The peers that are enabled, the contract addresses on other chains
    * @dev It emits a MultiplePeersEnabled event
    */ 
    function batchSetPeers(uint32[] memory _chainIds, bytes32[] memory _peers) external onlyOwner {
        uint256 chainIdsLength = _chainIds.length;
        uint256 peersLength = _peers.length;

        if(chainIdsLength == 0 || peersLength == 0) revert MonStaking__ArrayLengthCannotBeZero();
        if(chainIdsLength > MAX_SUPPOERTED_CHAINS) revert MonStaking__SupportedChainLimitReached();
        if(chainIdsLength != peersLength) revert MonStaking__PeersMismatch();

        for (uint256 i = 0; i < chainIdsLength; i++) {
            _setPeer(_chainIds[i], _peers[i]);
        }

        emit MultiplePeersEnabled(_chainIds, _peers);
    }

    /**
    * @notice It is used to be capable of receiving nfts
    * @dev It is called when safeTransferFrom is called on the NFT token
    */
    function onERC721Received(address, /*_operator*/ address, /*_from*/ uint256, /*_tokenId*/ bytes calldata /*_data*/ )
        external
        pure
        override
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }

    /**
    * @notice It is overriding the standard Ownable behaviour to avoid losing ownership of the contract
    * @notice If ownership is lost it will not be possible to perform critical functions such as adding new chains
    */
    function renounceOwnership() public view override onlyOwner {
        revert MonStaking__OwnershipCannotBeRenounced();
    }

    /**
    * @notice It is overriding the standard Ownable behaviour to avoid one step ownership transferral 
    * @dev LayerZero OApp implementaiton is using standard Ownable so it is needed to override this function
    */
    function transferOwnership(address /** newOwner*/) public view override onlyOwner {
        revert MonStaking__OwnershipCannotBeDirectlyTransferred();
    }

    /**
    * @notice It is used to batch evaluate the cost of multiple chain messages
    * @param _dstEids - The destination eids
    * @param _message - The message that is sent
    * @param _extraSendOptions - The extra send options
    * @param _payInLzToken - The flag that tells if the payment is in LZ token or native tokens 
    */
    function _batchQuote(
        uint32[] memory _dstEids,
        bytes memory _message,
        bytes memory _extraSendOptions,
        bool _payInLzToken
    ) public view returns (MessagingFee memory totalFee) {
        for (uint i = 0; i < _dstEids.length; i++) {
            MessagingFee memory fee = _quote(_dstEids[i], _message, _extraSendOptions, _payInLzToken);
            totalFee.nativeFee += fee.nativeFee;
            totalFee.lzTokenFee += fee.lzTokenFee;
        }
    }

    /**
    * @notice It is used to update the user state
    * @notice It updates points and time info
    * @param _user - The user for which the state is updated
    * @dev It is performed each time a change in balance occurs
    */
    function _updateUserState(address _user) internal {
        uint256 userTokenBalance = s_userStakedTokenAmount[_user];
        uint256 userNftBalance = s_userNftAmount[_user];
        uint256 lastUpdatedTimestamp = s_userLastUpdatedTimestamp[_user];

        _updateUserPoints(userTokenBalance, userNftBalance, lastUpdatedTimestamp, _user);
        _updateUserTimeInfo(_user);
    }

    /**
    * @notice It updates the user points
    * @param _userTokenBalance - The token balance of the user
    * @param _userNftBalance - The nft balance of the user
    * @param _lastUpdatedTimestamp - The last updated timestamp of the user
    * @param _user - The user for which the points are updated
    */
    function _updateUserPoints(
        uint256 _userTokenBalance,
        uint256 _userNftBalance,
        uint256 _lastUpdatedTimestamp,
        address _user
    ) internal {
        bool isPremium = s_isUserPremium[_user];
        s_userPoints[_user] += _calculateTokenPoints(_userTokenBalance, _lastUpdatedTimestamp, block.timestamp, isPremium) + _calculateNftPoints(_userNftBalance, _lastUpdatedTimestamp, block.timestamp, isPremium);
    }

    /**
    * @notice It updated the user time info
    * @param _user - The user for which the time info is updated
    */
    function _updateUserTimeInfo(address _user) internal {
        s_userLastUpdatedTimestamp[_user] = block.timestamp;
    }

    /**
    * @notice It clears the user time info
    * @param _user - The user for which the time info is cleared
    * @dev It happens when the user totally unstakes
    */
    function _clearUserTimeInfo(address _user) internal {
        delete s_userLastUpdatedTimestamp[_user];
    }

    /**
    * @notice It calculates the user points accrued from the token staking
    * @param _tokenAmount - The amount of tokens staked
    * @param _lastTimestamp - The last updated timestamp
    * @param _currentTimestamp - The current timestamp
    * @param _isPremium - The flag that tells if the user is premium
    * @return The points accrued from the token staking (uint256)
    */
    function _calculateTokenPoints(
        uint256 _tokenAmount,
        uint256 _lastTimestamp,
        uint256 _currentTimestamp,
        bool _isPremium
    ) internal view returns (uint256) {
        uint256 multiplier = _isPremium ? s_tokenPremiumMultiplier : s_tokenBaseMultiplier;
        uint256 timeDiff = _currentTimestamp - _lastTimestamp;
        uint256 points = _tokenAmount * multiplier * timeDiff;
        return _enforcePointDecimals(points) / i_monsterTokenDecimals / BPS;
    }

    /**
    * @notice It calculates the user points accrued from the nft staking
    * @param _nftAmount - The amount of nfts staked
    * @param _lastTimestamp - The last updated timestamp
    * @param _currentTimestamp - The current timestamp
    * @param _isPremium - The flag that tells if the user is premium
    * @return The points accrued from the nft staking (uint256)
    */
    function _calculateNftPoints(uint256 _nftAmount, uint256 _lastTimestamp, uint256 _currentTimestamp, bool _isPremium)
        internal
        view
        returns (uint256)
    {
        uint256 multiplier = _isPremium ? s_nftPremiumMultiplier : s_nftBaseMultiplier;
        uint256 timeDiff = _currentTimestamp - _lastTimestamp;
        uint256 points = _nftAmount * multiplier * timeDiff;
        return _enforcePointDecimals(points) / BPS;
    }

    /**
    * @notice It is a helper function that adds decimals to the amount of points
    * @dev It is needed not to lose decimal precision
    */ 
    function _enforcePointDecimals(uint256 _points) internal pure returns (uint256) {
        return _points * POINTS_DECIMALS;
    }

    /**
    * @notice It is used to enable the premium status of a user on a chain
    * @param _chainId - The chain id on which the user is enabled
    * @param _user - The user for which the premium status is enabled
    * @dev It first evaluates the chainId % BITMAP_BOUND to get the index of the chain in the bitmap
    * @dev It creates a bitmask by shifting 1 to the left by the index of the chain
    * @dev It then performs a bitwise OR operation to enable the premium status
    */
    function _enableChainPremium(uint32 _chainId, address _user) internal {
        
        uint256 chainIndex = _getChainIndex(_chainId);

        if (_isChainPremium(s_isUserPremiumOnOtherChains[_user], _chainId)) {
            s_userChainIndexCollisions[_user][chainIndex]++;
        }
        s_isUserPremiumOnOtherChains[_user] |= _getBitmask(chainIndex);
    }

    /**
    * @notice It is used to disable the premium status of a user on a chain
    * @param _chainId - The chain id on which the user is disabled
    * @param _user - The user for which the premium status is disabled
    * @dev It first evaluates the chainId % BITMAP_BOUND to get the index of the chain in the bitmap
    * @dev It creates a bitmask by shifting 1 to the left by the index of the chain
    * @dev It then performs a bitwise AND operation on the reversed bitmask to disable the premium status
    */
    function _disableChainPremium(uint32 _chainId, address _user) internal {

        uint256 chainIndex = _getChainIndex(_chainId);

        if (s_userChainIndexCollisions[_user][chainIndex] > 0){
            s_userChainIndexCollisions[_user][chainIndex]--;
        }else {
            s_isUserPremiumOnOtherChains[_user] &= ~(_getBitmask(chainIndex));
        }
    }

    /**
    * @notice It is used to get the index of the chain in the bitmap
    * @param _chainId - The chain id for which the index is calculated
    * @return The index of the chain in the bitmap (uint256)
    */
    function _getChainIndex(uint32 _chainId) internal pure returns(uint256){
        return _chainId % BITMAP_BOUND;
    }

    /**
    * @notice It is used to get the bitmask of the chain
    * @param _chainIndex - the index retrived after the modulus operation
    * @return The bitmask of the chain (uint256)
    * @dev It shifts 1 to the left by the index of the chain
    */
    function _getBitmask(uint256 _chainIndex) internal pure returns(uint256){
        return 1 << _chainIndex;
    }

    /**
    * @notice It is used to check if the user is premium on a chain
    * @param _bitmap - The bitmap of the user
    * @param _chainId - The chain id on which the user is checked
    * @return The flag that tells if the user is premium on the chain (bool)
    * @dev It performs a bitwise AND operation on the bitmap and the bitmask of the chain
    * @dev It enables to check if the user is premium on the chain in o(1) time
    */
    function _isChainPremium(uint256 _bitmap, uint32 _chainId) internal pure returns(bool){
        return (_bitmap & _getBitmask(_getChainIndex(_chainId))) != 0;
    }

    /**
    * @notice It is used to toggle the delegation of an nft
    * @param _user - The user for which the nft is delegated
    * @param _tokenId - The id of the nft
    * @param _isDelegated - The flag that tells if the nft is delegated
    */
    function _toggleNftDelegation(address _user, uint256 _tokenId, bool _isDelegated) internal {
        i_delegateRegistry.delegateERC721(_user, i_nftToken, _tokenId, bytes32(0), _isDelegated);
    }

    /**
    * @notice It allows to check if a user is premium on other chains in o(1) time
    * @param _user - The user for which the premium status is checked
    * @return The flag that tells if the user is premium on other chains (bool)
    */
    function _isUserPremiumOnOtherChains(address _user) internal view returns (bool) {
        return s_isUserPremiumOnOtherChains[_user] > 0;
    }

    /**
    * @notice It is used to update the premium status of a user on other chains
    * @param _user - The user for which the premium status is updated
    * @param _isPremium - The flag that tells if the user is premium
    * @dev It is used when a user is totally unstaking or is become premium when staking
    * @dev It emits a ChainsUpdated event
    */
    function _updateOtherChains(address _user, bool _isPremium) internal {

        uint256 chainsLength = s_supportedChains.length;

        uint32[] memory supportedChains = new uint32[](chainsLength);
        for (uint256 i = 0; i < chainsLength; i++) {
            supportedChains[i] = s_supportedChains[i];
        }


        MessagingFee memory totalFee = _batchQuote(supportedChains, abi.encode(_user, _isPremium), "", msg.value <= 0);

        if(msg.value > 0 && msg.value < totalFee.nativeFee) revert MonStaking__NotEnoughNativeTokens();

        uint256 totalNativeFeeUsed = 0;
        uint256 remainingValue = msg.value;

        for (uint256 i = 0; i < chainsLength; i++) {
            uint32 chainId = supportedChains[i];
            MessagingFee memory fee = _quote(chainId, abi.encode(_user, _isPremium), "", msg.value <= 0);

            if(msg.value > 0) {
                if(remainingValue < fee.nativeFee) revert MonStaking__NotEnoughNativeTokens();
                remainingValue -= fee.nativeFee;
            }

            totalNativeFeeUsed += fee.nativeFee;

            _lzSend(chainId, abi.encode(_user, _isPremium), "", fee, _user);
        }

        if(remainingValue > 0) {
            (bool success, ) = _user.call{value: remainingValue}("");
            if (!success) revert MonStaking__TransferFailed();
        }

        emit ChainsUpdated(supportedChains, _user, _isPremium);
    }


    /**
    * @notice It is the internal function responsible for handling received messages
    * @notice security checks on the caller are made by the external function implemented by LayerZero
    * @param _origin - The origin struct of the message
    * @param _message - The message that is received
    * @dev It is used to update the premium status of a user on a chain
    * @dev It emits a UserChainPremimUpdated event
    */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 /** _guid*/,
        bytes calldata _message,
        address /** _executor*/,
        bytes calldata /** _extraData*/
    ) internal override {

        (address user, bool isPremium) = abi.decode(_message, (address, bool));

        _updateUserState(user);

        uint32 chainId = _origin.srcEid; 

        isPremium ? _enableChainPremium(chainId, user) : _disableChainPremium(chainId, user);

        if (!s_isUserPremium[user] && isPremium) s_isUserPremium[user] = isPremium;

        if (
            s_isUserPremium[user] && !_isUserPremiumOnOtherChains(user) && !isPremium
            && s_userStakedTokenAmount[user] == 0 && s_userNftAmount[user] == 0
        ) s_isUserPremium[user] = isPremium;

        emit UserChainPremimUpdated(chainId, user, isPremium);
    }

    /** 
    * @notice It is used to set new chains and updating or removing already existing ones
    * @dev The original LayerZero Implementation has been overridden in order to abide by the system architecture
    * @param _eid - The chain id of the chain that is set
    * @param _peer - The address of the staking contract on the other chain
    */
    function _setPeer(uint32 _eid, bytes32 _peer) internal override {

        uint256 supportedChainsLength = s_supportedChains.length;
        bool isChainAlreadySupported = s_otherChainStakingContract[_eid] != bytes32(0);

        if(supportedChainsLength >= MAX_SUPPOERTED_CHAINS && !isChainAlreadySupported) revert MonStaking__SupportedChainLimitReached();

        uint256 index = s_chainIndex[_eid];

        s_otherChainStakingContract[_eid] = _peer;
        if(!isChainAlreadySupported) {
            s_supportedChains.push(_eid);
            s_chainIndex[_eid] = supportedChainsLength;
        }else if(isChainAlreadySupported && _peer == bytes32(0)) {
            s_supportedChains[index] = s_supportedChains[supportedChainsLength];
            s_chainIndex[s_supportedChains[index]] = index;
            s_supportedChains.pop();
        }else {
            s_supportedChains[index] = _eid;
        }

        super._setPeer(_eid, _peer);
    }
}
