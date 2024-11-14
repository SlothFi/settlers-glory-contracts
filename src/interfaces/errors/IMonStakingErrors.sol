// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

interface IMonStakingErrors {
    
    /// @dev Throws if the address is 0
    error MonStaking__ZeroAddress();

    /// @dev Throws if the amount is 0
    error MonStaking__ZeroAmount();

    /// @dev Throws if the chainId is 0
    error MonStaking__ZeroChainId();

    /// @dev Throws if the timelock has not passed when trying to claim a UserUnstakeRequest
    error MonStaking__TimelockNotPassed();

    /// @dev Throws if the token base multiplier is 0 or greater than the token premium multiplier
    error MonStaking__InvalidTokenBaseMultiplier();

    /// @dev Throws if the token premium multiplier is 0 or lower than the token base multiplier
    error MonStaking__InvalidTokenPremiumMultiplier();

    /// @dev Throws if the NFT base multiplier is 0 or greater than the NFT premium multiplier
    error MonStaking__InvalidNftBaseMultiplier();

    /// @dev Throws if the NFT premium multiplier is 0 or lower than the NFT base multiplier
    error MonStaking__InvalidNftPremiumMultiplier();

    /// @dev Throws if the enum given to the setter is not included among the Multipliers
    error MonStaking__InvalidMultiplierType();

    /// @dev Throws if the token decimals are 0
    error MonStaking__InvalidTokenDecimals();

    /// @dev Throws if the token id is 0 or greater than the max supply
    error MonStaking__InvalidTokenId();

    /// @dev Throws if msg.sender is not the LiquidStakedMonster contract
    error MonStaking__NotLSMContract();

    /// @dev Throws if the chain is not supported
    error MonStaking__ChainNotSupported();

    /// @dev Throws if trying to ping a new chain where the user is already premium
    error MonStaking__UserAlreadyPremium();

    /// @dev Throws if the user tries to ping a new chain if not premium
    error MonStaking__UserNotPremium();

    /// @dev Throws if user tries to perform a interchain communication and msg.value is not sufficient
    error MonStaking__NotEnoughNativeTokens();

    /// @dev Throws if user ties to unstake an amount which is bigger than his balance
    error MonStaking__NotEnoughMonsterTokens();

    /// @dev Throws if a premium user tries to totally unstake without passing from the designated function - requireUnstakeAll()
    error MonStaking__CannotTotallyUnstake();

    /// @dev Throws if user tries to batch withdraw more than 20 nfts at one time
    error MonStaking__TokenIdArrayTooLong();

    /// @dev It is thrown if the owner tries to renounce ownership
    error MonStaking__OwnershipCannotBeRenounced();

    /// @dev It is thrown if the owner tries to transfer ownership in one step
    error MonStaking__OwnershipCannotBeDirectlyTransferred();

    /// @dev Throws if the msg.sender is not the proposed owner
    error MonStaking__NotProposedOwner();

    /// @dev Throws if the owner tries to add more than 10 chains
    error MonStaking__SupportedChainLimitReached();

    /// @dev Throws if in batchSetPeers the chain id length is not equal to the address length
    error MonStaking__PeersMismatch();

    /// @dev Throws if the array length is 0
    error MonStaking__ArrayLengthCannotBeZero();

    /// @dev Throws if the array length is 0
    error MonStaking__InvalidIdArrayLength();

    /// @dev Throws if the nft is not owned by the msg.sender
    error MonStaking__NotNftOwner();

    /// @dev Throws when a native transfer fails
    error MonStaking__TransferFailed();
}