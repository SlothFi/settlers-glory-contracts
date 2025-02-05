// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

interface IMonStaking {

    function stakeTokens(uint256 _amount) external payable;
    function stakeNft(uint256 _tokenId) external payable;
    function unstakeTokens(uint256 _amount) external;
    function unstakeNft(uint256 _tokenId) external;
    function requireUnstakeAll() external payable;
    function claimUnstakedAssets(uint256[] calldata) external;
    function updateStakingBalance(address _from, address _to, uint256 _amount) external payable;
    function pingNewChainContract(uint32 _chainId) external payable;
    function syncPoints() external;
}
