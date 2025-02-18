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
    address public owner;

    /// @notice ID of the locked NFT
    uint256 public tokenId;

    /// @notice Timestamp when NFT unlocks
    uint256 public unlockTime;

    /// @notice Initialization status
    bool private initialized;

    /// @notice Thrown when non-owner tries to access
    error NotOwner();

    /// @notice Thrown when contract is already initialized
    error AlreadyInitialized();

    /// @notice Thrown when address is invalid
    error NotValidAddress();

    /// @notice Modifier to restrict access to the owner
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @notice Initializes the lock contract
    function initialize(address _owner, uint256 _tokenId, uint256 _unlockTime) external virtual {
        if (initialized) revert AlreadyInitialized();
        if (_owner == address(0)) revert NotValidAddress();
        owner = _owner;
        tokenId = _tokenId;
        unlockTime = _unlockTime;
        initialized = true;
    }

    /// @notice Returns the owner of the locked NFT
    function getOwner() external view returns (address) {
        return owner;
    }

    /// @notice Returns the ID of the locked NFT
    function getTokenId() external view returns (uint256) {
        return tokenId;
    }

    /// @notice Returns the unlock time of the locked NFT
    function getUnlockTime() external view returns (uint256) {
        return unlockTime;
    }

    /// @notice Withdraws the locked NFT
    function withdraw(address nftContract, uint256 tokenId) external virtual;
}