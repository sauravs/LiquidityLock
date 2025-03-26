pragma solidity 0.8.24;

/// @title ILiquidity Interface
/// @notice Interface for NFT liquidity locking contracts
/// @dev Defines the core functionality for locking and retrieving NFTs
interface ILiquidity {
    /// @notice Initializes the lock contract with owner and token details
    /// @param _owner The address that will own this lock
    /// @param _tokenId The ID of the NFT being locked
    /// @param _unlockTime The timestamp when the NFT becomes unlockable
    /// @dev Should only be callable once during contract setup
    function initialize(address _owner, uint256 _tokenId, uint256 _unlockTime) external;

    /// @notice Withdraws the locked NFT to the owner
    /// @param nftContract The address of the NFT contract
    /// @param tokenId The ID of the NFT to withdraw
    /// @dev Implementation should include appropriate access control and timing validation
    function withdraw(address nftContract, uint256 tokenId) external;

    /// @notice Returns the owner of the locked NFT
    /// @return The address of the lock owner
    /// @dev Owner has withdrawal rights after unlock conditions are met
    function getOwner() external view returns (address);

    /// @notice Returns the ID of the locked NFT
    /// @return The token ID of the locked NFT
    function getTokenId() external view returns (uint256);

    /// @notice Returns the unlock time of the locked NFT
    /// @return The timestamp when the NFT becomes unlockable
    function getUnlockTime() external view returns (uint256);

    /// @notice Returns the start time of the locked NFT
    /// @return The timestamp when the NFT was locked
    function getStartTime() external view returns (uint256);
}
