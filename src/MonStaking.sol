// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {OApp, Origin, MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IMonERC721} from "./interfaces/IMonERC721.sol";
import {IDelegateRegistry} from "./interfaces/IDelegateRegistry.sol";

contract MonStaking is OApp {
    using SafeERC20 for IERC20;

    enum Multipliers {
        TOKEN_BASE,
        TOKEN_PREMIUM,
        NFT_BASE,
        NFT_PREMIUM
    }

    struct TimeInfo {
        uint256 lastUpdatedTimestamp;
        uint256 startingTimestamp;
    }

    error MonStaking__ZeroAddress();
    error MonStaking__ZeroAmount();
    error MonStaking__ZeroChainId();
    error MonStaking__TimelockNotPassed();
    error MonStaking__InvalidTokenBaseMultiplier();
    error MonStaking__InvalidTokenPremiumMultiplier();
    error MonStaking__InvalidNftBaseMultiplier();
    error MonStaking__InvalidNftPremiumMultiplier();
    error MonStaking__InvalidMultiplierType();
    error MonStaking__InvalidTokenDecimals();
    error MonStaking__NotLSMContract();

    event TokenBaseMultiplierChanged(uint256 indexed _newValue);
    event TokenPremiumMultiplierChanged(uint256 indexed _newValue);
    event NftBaseMultiplierChanged(uint256 indexed _newValue);
    event NftPremiumMultiplierChanged(uint256 indexed _newValue);

    uint256 public constant BPS = 10_000;
    uint256 public constant POINTS_DECIMALS = 1e18;
    uint256 public constant MAX_SUPPOERTED_CHAINS = 10;
    uint256 public constant TIME_LOCK_DURATION = 3 hours;

    uint256 public immutable i_crationTimestamp;
    uint256 public immutable i_premiumDuration;
    uint256 public immutable i_endPremiumTimestamp;
    address public immutable i_monsterToken;
    uint256 public immutable i_monsterTokenDecimals;
    address public immutable i_lsToken;
    uint256 public immutable i_lsTokenDecimals;
    address public immutable i_nftToken;
    uint256 public immutable i_nftMaxSupply;
    IDelegateRegistry public immutable i_delegateRegistry;

    uint256 public s_tokenBaseMultiplier;
    uint256 public s_tokenPremiumMultiplier;
    uint256 public s_nftBaseMultiplier;
    uint256 public s_nftPremiumMultiplier;

    mapping(address user => TimeInfo timeInfo) public s_userTimeInfo;
    mapping(address user => uint256 nftAmount) public s_userNftAmount;
    mapping(uint256 tokenId => address owner) public s_nftOwner;
    mapping(address user => uint256 stakedTokenAmount) public s_userStakedTokenAmount;
    mapping(uint32 chainId => bytes32 otherChainStaking) public s_otherChainStakingContract;
    uint32[MAX_SUPPOERTED_CHAINS] public s_supportedChains; // this is made for saving gas
    mapping(uint32 chainId => mapping(address user => bool isPremium)) public s_isUserPremium;

    modifier onlyLSMContract() {
        if (msg.sender != i_lsToken) revert MonStaking__NotLSMContract();
        _;
    }

    modifier ifTimelockAllows() {
        if (s_userTimeInfo[msg.sender].startingTimestamp + TIME_LOCK_DURATION > block.timestamp) {
            revert MonStaking__TimelockNotPassed();
        }
        _;
    }

    constructor(
        address _endpoint,
        address _delegated,
        uint256 _premiumDuration,
        address _monsterToken,
        address _lsToken,
        address _nftToken,
        uint256 _tokenBaseMultiplier,
        uint256 _tokenPremiumMultiplier,
        uint256 _nftBaseMultiplier,
        uint256 _nftPremiumMultiplier,
        address _delegateRegistry
    ) OApp(_endpoint, _delegated) Ownable(_delegated) {
        if (
            _monsterToken == address(0) || _lsToken == address(0) || _nftToken == address(0)
                || _delegateRegistry == address(0)
        ) revert MonStaking__ZeroAddress();
        if (_premiumDuration == 0) revert MonStaking__ZeroAmount();
        if (_tokenBaseMultiplier == 0 || _tokenBaseMultiplier >= _tokenPremiumMultiplier) {
            revert MonStaking__InvalidTokenBaseMultiplier();
        }
        if (_tokenPremiumMultiplier == 0) revert MonStaking__InvalidTokenPremiumMultiplier();
        if (_nftBaseMultiplier == 0 || _nftBaseMultiplier >= _nftPremiumMultiplier) {
            revert MonStaking__InvalidNftBaseMultiplier();
        }
        if (_nftPremiumMultiplier == 0) revert MonStaking__InvalidNftPremiumMultiplier();

        i_crationTimestamp = block.timestamp;
        i_premiumDuration = _premiumDuration;
        i_endPremiumTimestamp = i_crationTimestamp + i_premiumDuration;
        i_monsterToken = _monsterToken;
        i_monsterTokenDecimals = IERC20Metadata(_monsterToken).decimals();
        if (i_monsterTokenDecimals == 0) revert MonStaking__InvalidTokenDecimals();
        i_lsToken = _lsToken;
        i_monsterTokenDecimals = IERC20Metadata(_monsterToken).decimals();
        if (i_lsTokenDecimals == 0) revert MonStaking__InvalidTokenDecimals();
        i_nftToken = _nftToken;
        i_nftMaxSupply = IMonERC721(_nftToken).maxSupply();
        i_delegateRegistry = IDelegateRegistry(_delegateRegistry);

        s_tokenBaseMultiplier = _tokenBaseMultiplier;
        s_tokenPremiumMultiplier = _tokenPremiumMultiplier;
        s_nftBaseMultiplier = _nftBaseMultiplier;
        s_nftPremiumMultiplier = _nftPremiumMultiplier;
    }

    function stakeTokens(uint256 _amount) external payable {}

    function stakeNft(uint256 _tokenId) external payable {}

    function unstakeTokens(uint256 _amount) external payable ifTimelockAllows {}

    function unstakeNft(uint256 _tokenId) external payable ifTimelockAllows {}

    function updateStakingBalance(address _from, address _to, uint256 _amount) external payable onlyLSMContract {}

    function pingNewChainContract(uint32 _chainId) external payable {} // made if we are premium here and we want to signal it to a newly deployed contract on other chain

    function syncPoints() external {}

    function setMultipliers(Multipliers _multiplierType, uint256 _value) external onlyOwner {
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

    function _updateUserState(address _user) internal {}

    function _updateUserPoints() internal {}

    function _updateUserTimeInfo() internal {}

    function _calculateTokenPoints() internal pure returns (uint256) {}

    function _calculateNftPoints() internal pure returns (uint256) {}

    function _isUserPremium() internal view returns (bool) {}

    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) internal override {}
}
