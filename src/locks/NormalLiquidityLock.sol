pragma solidity 0.8.24;

import "../LiquidityLockBase.sol";

/// @title NormalLiquidity
/// @notice Implementation of a time-locked NFT liquidity lock
/// @dev Inherits from BaseLiquidity and adds time-based withdrawal restrictions

contract NormalLiquidity is BaseLiquidity {
    /// @notice Error thrown when attempting to withdraw before unlock time
    /// @param currentTime The current block timestamp
    /// @param unlockTime The timestamp when withdrawal becomes available
    error TokenStillLocked(uint256 currentTime, uint256 unlockTime);

    /// @notice Allows the owner to withdraw their locked NFT after unlock time
    /// @param nftContract The address of the NFT contract
    /// @param tokenId The ID of the NFT to withdraw
    /// @dev Reverts if called before unlockTime, only callable by owner
    function withdraw(address nftContract, uint256 tokenId) external override onlyOwner {
        if (block.timestamp < unlockTime) {
            revert TokenStillLocked(block.timestamp, unlockTime);
        }
        IERC721(nftContract).safeTransferFrom(address(this), owner, tokenId);
    }
}
