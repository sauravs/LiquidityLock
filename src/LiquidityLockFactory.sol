pragma solidity 0.8.24;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./locks/BasicLiquidityLock.sol";
import "./locks/NormalLiquidityLock.sol";

/// @title LiquidityLockFactory
/// @notice Factory contract for creating NFT liquidity locks
/// @dev Uses OpenZeppelin's Clones for minimal proxy pattern and ReentrancyGuard for security
contract LiquidityLockFactory is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Clones for address;

    /// @notice Types of locks that can be created
    /// @dev BASIC has no time lock, NORMAL has time lock

    enum LockType {
        BASIC,
        NORMAL
    }

    /// @notice Structure to store information about created locks
    /// @param lockAddress Address of the deployed lock contract
    /// @param lockType Type of the lock (BASIC or NORMAL)

    struct LockInfo {
        address lockAddress;
        LockType lockType;
    }

    /// @notice Address that can modify fee parameters
    address public feeAdmin = 0x80AB0Cb57106816b8eff9401418edB0Cb18ed5c7;

    /// @notice Address that receives the lock creation fees
    address public feeCollector = 0xd561f11d4ddb6E86B613F1dAaDE6a1e8ab0e6187;

    /// @notice Token used for paying lock creation fees (USDC)

    IERC20 public lockFeeToken = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174); // USDC

    /// @notice Fee amount for creating a basic lock (20 USDC)
    uint256 public liquidityLockFeeAmountBasic = 20 * 10 ** 6; // 10 USDC

    /// @notice Fee amount for creating a normal lock (50 USDC)
    uint256 public liquidityLockFeeAmountNormal = 50 * 10 ** 6; //50 USDC

    /// @notice Implementation contract for basic locks

    address public immutable basicImpl;

    /// @notice Implementation contract for normal locks
    address public immutable normalImpl;

    /// @notice Mapping of user addresses to their created locks

    mapping(address => LockInfo[]) public userLocks;

    /// @notice Emitted when a new lock is created
    /// @param user Address of the lock creator
    /// @param lock Address of the created lock contract
    /// @param lockType Type of the created lock

    event LockCreated(address indexed user, address indexed lock, LockType indexed lockType);

    /// @notice Emitted when fee token is updated
    /// @param newFeeToken Address of the new fee token
    event FeeTokenUpdated(IERC20 indexed newFeeToken);

    /// @notice Emitted when fee admin is updated
    /// @param newFeeAdmin Address of the new fee admin
    event FeeAdminUpdated(address indexed newFeeAdmin);

    /// @notice Emitted when fee collector is updated
    /// @param newFeeCollector Address of the new fee collector
    event FeeCollectorUpdated(address indexed newFeeCollector);

    /// @notice Emitted when basic lock fee amount is updated
    /// @param newFee New fee amount for basic locks
    event FeeAmountBasicUpdated(uint256 indexed newFee);

    /// @notice Emitted when normal lock fee amount is updated
    /// @param newFee New fee amount for normal locks
    event FeeAmountNormalUpdated(uint256 indexed newFee);

    /// @notice Modifier to restrict access to fee admin

    modifier onlyFeeAdmin() {
        if (msg.sender != feeAdmin) revert NotFeeAdmin();
        _;
    }

    /// @notice Error message when caller is not fee admin
    error NotFeeAdmin();

    /// @notice Error message when deployment fails
    error DeploymentFailed();

    /// @notice Error message when address is not valid

    error NotValidAddress();

    /// @notice Initializes the factory with implementation contracts

    constructor() {
        basicImpl = address(new BasicLiquidity());
        normalImpl = address(new NormalLiquidity());
    }

    /// @notice Updates the fee token address
    /// @param _newFeeToken Address of the new fee token
    /// @dev Only callable by fee admin
    function updateLockFeeToken(IERC20 _newFeeToken) external onlyFeeAdmin {
        if (address(_newFeeToken) == address(0)) {
            revert NotValidAddress();
        }

        lockFeeToken = _newFeeToken;
        emit FeeTokenUpdated(_newFeeToken);
    }

    /// @notice Updates the fee admin address
    /// @param _newFeeAdmin Address of the new fee admin
    /// @dev Only callable by current fee admin
    function updateFeeAdmin(address _newFeeAdmin) external onlyFeeAdmin {
        if (address(_newFeeAdmin) == address(0)) {
            revert NotValidAddress();
        }

        feeAdmin = _newFeeAdmin;
        emit FeeAdminUpdated(_newFeeAdmin);
    }

    /// @notice Updates the fee collector address
    /// @param _newFeeCollector Address of the new fee collector
    /// @dev Only callable by fee admin
    function updateFeeCollector(address _newFeeCollector) external onlyFeeAdmin {
        if (address(_newFeeCollector) == address(0)) {
            revert NotValidAddress();
        }
        feeCollector = _newFeeCollector;
        emit FeeCollectorUpdated(_newFeeCollector);
    }

    /// @notice Updates the fee amount for basic locks
    /// @param _newFee New fee amount in fee token decimals
    /// @dev Only callable by fee admin
    function updatelockFeeAmountBasic(uint256 _newFee) external onlyFeeAdmin {
        liquidityLockFeeAmountBasic = _newFee;
        emit FeeAmountBasicUpdated(_newFee);
    }

    /// @notice Updates the fee amount for normal locks
    /// @param _newFee New fee amount in fee token decimals
    /// @dev Only callable by fee admin
    function updatelockFeeAmountNormal(uint256 _newFee) external onlyFeeAdmin {
        liquidityLockFeeAmountNormal = _newFee;
        emit FeeAmountNormalUpdated(_newFee);
    }

    /// @notice Creates a new lock contract
    /// @param nftContract Address of the NFT contract
    /// @param lockType Type of lock to create (BASIC or NORMAL)
    /// @param tokenId ID of the NFT to lock
    /// @param unlockTime Timestamp when the NFT can be withdrawn (only for NORMAL locks)
    /// @return lock Address of the created lock contract
    /// @dev Transfers NFT from sender to lock contract and charges creation fee
    function createLock(address nftContract, LockType lockType, uint256 tokenId, uint256 unlockTime)
        external
        nonReentrant
        returns (address lock)
    {
        lock = lockType == LockType.BASIC ? basicImpl.clone() : normalImpl.clone();

        if (lockType == LockType.BASIC) {
            BasicLiquidity(lock).initialize(msg.sender, tokenId, 0);
        } else {
            NormalLiquidity(lock).initialize(msg.sender, tokenId, unlockTime);
        }

        if (!isContractDeployed(address(lock))) {
            revert DeploymentFailed();
        }

        IERC721(nftContract).safeTransferFrom(msg.sender, lock, tokenId);

        lockFeeToken.safeTransferFrom(
            msg.sender,
            feeCollector,
            lockType == LockType.BASIC ? liquidityLockFeeAmountBasic : liquidityLockFeeAmountNormal
        );

        userLocks[msg.sender].push(LockInfo(lock, lockType));
        emit LockCreated(msg.sender, lock, lockType);
    }

    /// @notice Checks if a contract exists at the given address
    /// @param _contract Address to check
    /// @return bool True if contract exists, false otherwise
    /// @dev Uses assembly to check contract size

    function isContractDeployed(address _contract) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_contract)
        }
        return size > 0;
    }

    /// @notice Gets all locks created by a user
    /// @param user Address of the user
    /// @return Array of LockInfo structs containing lock details
    function getUserLocks(address user) external view returns (LockInfo[] memory) {
        return userLocks[user];
    }
}
