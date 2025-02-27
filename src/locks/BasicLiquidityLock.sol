pragma solidity 0.8.24;

import "../LiquidityLockBase.sol";

/// @title BasicLiquidity
/// @notice Contract for NFT liquidity locking without time lock
/// @dev Extends BaseLiquidity with basic locking functionality

contract BasicLiquidity is BaseLiquidity {
    /// @notice Thrown when token ID is invalid

    error InvalidTokenId();

    /// @notice Allows the owner to withdraw their locked NFT at any time
    /// @param nftContract The address of the NFT contract
    /// @param _tokenId The ID of the NFT to withdraw
    /// @dev Only callable by lock owner, transfers NFT directly to owner
    function withdraw(address nftContract, uint256 _tokenId) external override onlyOwner {
        if (nftContract == address(0)) revert NotValidAddress();


        if (_tokenId != this.getTokenId()) {
            revert InvalidTokenId();
        }

        IERC721(nftContract).safeTransferFrom(address(this), this.getOwner(), _tokenId);
    }
}
