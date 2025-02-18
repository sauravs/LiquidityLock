pragma solidity 0.8.24;

import "../LiquidityLockBase.sol";

/// @title BasicLiquidity
/// @notice Implementation of a basic NFT lock without time restrictions
/// @dev Inherits from BaseLiquidity and implements immediate withdrawal functionality
contract BasicLiquidity is BaseLiquidity {
    /// @notice Allows the owner to withdraw their locked NFT at any time
    /// @param nftContract The address of the NFT contract
    /// @param tokenId The ID of the NFT to withdraw
    /// @dev Only callable by lock owner, transfers NFT directly to owner
    function withdraw(address nftContract, uint256 tokenId) external override onlyOwner {
        IERC721(nftContract).safeTransferFrom(address(this), owner, tokenId); 
    }
}
