pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./interfaces/ILiquidity.sol";

/// @title BaseLiquidity
/// @notice Base contract for NFT liquidity locking functionality
/// @dev Abstract contract implementing core locking logic
abstract contract BaseLiquidity is ILiquidity, ERC721Holder {
    /// @notice Owner of the locked NFT
    /// @dev Address that can withdraw the NFT
    address private owner;

    /// @notice ID of the locked NFT
    uint256 private tokenId;

    /// @notice Timestamp when NFT unlocks
    uint256 private unlockTime;

    /// @notice Timestamp when NFT was locked

    uint256 private startTime;

    /// @notice Initialization status
    bool private initialized;

    /// @notice Thrown when non-owner tries to access
    error NotOwner();

    /// @notice Thrown when contract is already initialized
    error AlreadyInitialized();

    /// @notice Thrown when address is invalid
    error NotValidAddress();

    /// @notice Emitted when a new lock is initialized
    /// @param owner The address that owns the lock
    /// @param tokenId The ID of the locked NFT
    /// @param unlockTime The timestamp when the NFT becomes unlockable
    /// @param startTime The timestamp when the lock was created
    event LockInitialized(address indexed owner, uint256 indexed tokenId, uint256 unlockTime, uint256 startTime);

    /// @notice Modifier to restrict access to the owner
    /// @dev Reverts if caller is not the owner
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @notice Initializes the lock contract
    /// @param _owner The address that will own this lock
    /// @param _tokenId The ID of the NFT being locked
    /// @param _unlockTime The timestamp when the NFT becomes unlockable
    /// @dev Should only be callable once during contract setup
    function initialize(address _owner, uint256 _tokenId, uint256 _unlockTime) external virtual {
        if (initialized) revert AlreadyInitialized();
        if (_owner == address(0)) revert NotValidAddress();
        owner = _owner;
        tokenId = _tokenId;
        unlockTime = _unlockTime;
        startTime = block.timestamp;
        initialized = true;

        emit LockInitialized(_owner, _tokenId, _unlockTime, startTime);
    }

    /// @notice Returns the owner of the locked NFT
    /// @return The address of the lock owner
    function getOwner() external view returns (address) {
        return owner;
    }

    /// @notice Returns the ID of the locked NFT
    /// @return The token ID of the locked NFT
    function getTokenId() external view returns (uint256) {
        return tokenId;
    }
    /// @notice Returns the unlock time of the locked NFT
    /// @return The timestamp when the NFT becomes unlockable

    function getUnlockTime() external view returns (uint256) {
        return unlockTime;
    }

    /// @notice Returns the start time of the locked NFT
    /// @return The timestamp when the NFT was locked
    function getStartTime() external view returns (uint256) {
        return startTime;
    }

    /// @notice Withdraws the locked NFT
    function withdraw(address nftContract, uint256 tokenId) external virtual;
}
