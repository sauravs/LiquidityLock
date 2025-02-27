pragma solidity 0.8.24;

import "../LiquidityLockBase.sol";

/// @title NormalLiquidity
/// @notice Contract for NFT liquidity locking with time lock
/// @dev Extends BaseLiquidity with time lock functionality

contract NormalLiquidity is BaseLiquidity {
    /// @notice Thrown when token ID is invalid

    error InvalidTokenId();

    /// @notice Thrown when token is still locked
    error TokenStillLocked(uint256 currentTime, uint256 unlockTime);

    /// @notice Allows the owner to withdraw their locked NFT after the unlock time
    /// @param nftContract The address of the NFT contract
    /// @param _tokenId The ID of the NFT to withdraw
    /// @dev Only callable by lock owner, transfers NFT directly to owner

    function withdraw(address nftContract, uint256 _tokenId) external override onlyOwner {
        if (nftContract == address(0)) revert NotValidAddress();

        uint256 currentUnlockTime = this.getUnlockTime();
        if (block.timestamp < currentUnlockTime) {
            revert TokenStillLocked(block.timestamp, currentUnlockTime);
        }

        if (_tokenId != this.getTokenId()) {
            revert InvalidTokenId();
        }

        IERC721(nftContract).safeTransferFrom(address(this), this.getOwner(), _tokenId);
    }
}
