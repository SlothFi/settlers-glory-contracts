// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

interface IMonStakingEvents {

    /**
    * @notice Event emitted when the token base multiplier is changed
    * @param _newValue - The new value of the token base multiplier 
    */
    event TokenBaseMultiplierChanged(uint256 indexed _newValue);
    /**
    * @notice Event emitted when the token premium multiplier is changed
    * @param _newValue - The new value of the token premium multiplier 
    */
    event TokenPremiumMultiplierChanged(uint256 indexed _newValue);
    /**
    * @notice Event emitted when the NFT base multiplier is changed
    * @param _newValue - The new value of the NFT base multiplier 
    */
    event NftBaseMultiplierChanged(uint256 indexed _newValue);
    /**
    * @notice Event emitted when the NFT premium multiplier is changed
    * @param _newValue - The new value of the NFT premium multiplier 
    */
    event NftPremiumMultiplierChanged(uint256 indexed _newValue);
    /**
    * @notice Event emitted when a new chain is pinged to update a premium user state
    * @param _chainId - The chain id that is pinged
    * @param _user - The user that is being updated
    */
    event NewChainPinged(uint32 indexed _chainId, address indexed _user);
    /**
    * @notice Event emitted when the staking balance is updated
    * @dev This happens when a user buys something with LiquidStakedMonster tokens
    * @param _from - The address from which the amount is taken
    * @param _to - The address to which the amount is added
    * @param _amount - The amount that is transferred
    */
    event StakingBalanceUpdated(address indexed _from, address indexed _to, uint256 indexed _amount);
    /**
    * @notice Event emitted when tokens are staked
    * @param _user - The user that is staking the tokens
    * @param _amount - The amount of tokens that are staked
    */
    event TokensStaked(address indexed _user, uint256 indexed _amount);
    /**
    * @notice Event emitted when tokens are unstaked
    * @param _user - The user that is unstaking the tokens
    * @param _amount - The amount of tokens that are unstaked
    */
    event TokensUnstaked(address indexed _user, uint256 indexed _amount);
    /**
    * @notice Event emitted when an NFT is staked
    * @param _user - The user that is staking the NFT
    * @param _tokenId - The id of the NFT that is staked
    */
    event NftStaked(address indexed _user, uint256 indexed _tokenId);
    /**
    * @notice Event emitted when an NFT is unstaked
    * @param _user - The user that is unstaking the NFT
    * @param _tokenId - The id of the NFT that is unstaked
    */
    event NftUnstaked(address indexed _user, uint256 indexed _tokenId);
    /**
    * @notice Event emitted when the premium state of a user is updated in other chains
    * @param _chainIds - The chain ids that are updated
    * @param _user - The user that is being updated
    * @param _isPremium - The new premium state of the user
    */
    event ChainsUpdated(uint32[] indexed _chainIds, address indexed _user, bool indexed _isPremium);
    /**
    * @notice Event emitted when other chains call the contract to update the premium state of a user
    * @param _chainId - The chain id that is calling
    * @param _user - The user that is being updated
    * @param _isPremium - The new premium state of the user
    */
    event UserChainPremimUpdated(uint32 indexed _chainId, address indexed _user, bool indexed _isPremium);
    /**
    * @notice Event emitted when the points of a user are synced
    * @param _user - The user that is being updated
    * @param _totalPoints - The total points of the user
    */
    event PointsSynced(address indexed _user, uint256 indexed _totalPoints);
    /**
    * @notice Event emitted when a premium user requires a total unstake
    * @param _user - The user that is requiring the total unstake
    * @param _tokenAmount - The amount of tokens that are required to be unstaked
    * @param _nftAmount - The amount of NFTs that are required to be unstaked
    */
    event TotalUnstakeRequired(address indexed _user, uint256 indexed _tokenAmount, uint256 indexed _nftAmount);
    /**
    * @notice Event emitted when the user claims the unstaked assets
    * @param _user - The user that is claiming the assets
    * @param _tokenAmount - The amount of tokens that are claimed
    * @param _tokenIds - The ids of the NFTs that are claimed
    */
    event UnstakedAssetsClaimed(address indexed _user, uint256 indexed _tokenAmount, uint256[] indexed _tokenIds);
    /**
    * @notice Event emitted when the new owner is proposed
    * @param _newOwner - The address of the new owner
    */
    event NewOwnerProposed(address indexed _newOwner);
    /**
    * @notice Event emitted when the ownership is claimed
    * @param _newOwner - The address of the new owner
    * @param _oldOwner - The address of the old owner
    */
    event OwnershipClaimed(address indexed _newOwner, address indexed _oldOwner);
    /**
    * @notice Event emitted when multiple peers are enabled
    * @param _chainIds - The chain ids that are enabled
    * @param _peers - The peers that are enabled
    */
    event MultiplePeersEnabled(uint32[] indexed _chainIds, bytes32[] indexed _peers);
    /**
    * @notice Event emitted when a chain is removed
    * @param _chainId - The chain id that is removed
    */
    event ChainRemoved(uint32 indexed _chainId);
    /**
    * @notice Event emitted when a user batch unstakes NFTs
    * @param _tokenIds - The ids of the NFTs that are unstaked
    * @param _user - The user that is unstaking the NFTs
    */
    event NftBatchUnstaked(uint256[] indexed _tokenIds, address indexed _user);

}
