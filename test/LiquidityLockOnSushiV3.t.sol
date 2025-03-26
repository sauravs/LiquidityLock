// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/LiquidityLockFactory.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./utils/IUniswapV3Factory.sol";
import "./utils/INonfungiblePositionManager.sol";
import "./utils/IUniswapV3Pool.sol";
import "../src/interfaces/ILiquidity.sol";

contract MockDugi is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract LiquidityLockTestForSushi is Test {
    LiquidityLockFactory public liquidityFactory;
    MockDugi public mockDugi;
    ERC20 usdc;
    INonfungiblePositionManager npm;
    IUniswapV3Factory uniFactory;

    uint256 polygonMainnetFork;

    // polygon mainnet addresses(related to SUSHI)
    address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address constant USDC_WHALE = 0x94dBF04E273d87e6D9Bed68c616F43Bf86560C74;
    address constant SUSHISWAP_V3_FACTORY = 0x917933899c6a5F8E37F31E19f92CdBFF7e8FF0e2;
    address constant POSITION_MANAGER = 0xb7402ee99F0A008e461098AC3A27F4957Df89a40;

    uint24 constant POOL_FEE = 3000;
    uint256 constant INITIAL_DUGI_MINT = 1000000 * 1e18;
    uint256 constant INITIAL_USDC_AMOUNT = 100 * 1e6;

    uint256 constant LOCK_DURATION = 7 days;
    uint256 tokenId;

    address public liquidityProvider = makeAddr("liquidityProvider");
    address public randomUser = makeAddr("randomUser");
    address public feeCollector;
    address public feeAdmin;

    function setUp() public {
        string memory POLYGON_RPC_URL = vm.envString("POLYGON_RPC_URL");
        polygonMainnetFork = vm.createFork(POLYGON_RPC_URL);
        vm.selectFork(polygonMainnetFork);

        // Initialize contracts
        liquidityFactory = new LiquidityLockFactory();
        npm = INonfungiblePositionManager(POSITION_MANAGER);
        uniFactory = IUniswapV3Factory(SUSHISWAP_V3_FACTORY);
        mockDugi = new MockDugi("mockDugiCoin", "mockDugi");

        // use real USDC contract
        usdc = ERC20(USDC);

        // impersonate USDC holder and fund liquidity provider
        vm.prank(USDC_WHALE);
        usdc.transfer(liquidityProvider, 1000 * 1e6); // 1000 USDC
            // approve USDC for fee payment
        // vm.startPrank(liquidityProvider);
        // usdc.approve(address(locker), type(uint256).max);
        // vm.stopPrank();

        // mint mockDugi to provider
        vm.prank(address(this));
        mockDugi.mint(liquidityProvider, 10_000_000 * 1e18);

        // approve tokens for UniswapV3
        vm.startPrank(liquidityProvider);
        mockDugi.approve(POSITION_MANAGER, type(uint256).max);
        IERC20(USDC).approve(POSITION_MANAGER, type(uint256).max);

        // create and initialize pool if doesn't exist
        address pool = uniFactory.getPool(USDC, address(mockDugi), POOL_FEE);
        if (pool == address(0)) {
            pool = uniFactory.createPool(USDC, address(mockDugi), POOL_FEE);
            IUniswapV3Pool(pool).initialize(79228162514264337593543950336);
        }

        // create UniswapV3 position
        (tokenId,,,) = npm.mint(
            INonfungiblePositionManager.MintParams({
                token0: address(USDC),
                token1: address(mockDugi),
                fee: POOL_FEE,
                tickLower: -887220,
                tickUpper: 887220,
                amount0Desired: INITIAL_USDC_AMOUNT,
                amount1Desired: INITIAL_DUGI_MINT,
                amount0Min: 0,
                amount1Min: 0,
                recipient: liquidityProvider,
                deadline: block.timestamp + 1
            })
        );

        vm.stopPrank();

        feeCollector = liquidityFactory.feeCollector();
        feeAdmin = liquidityFactory.feeAdmin();
    }

    function testCreateBasicLock() public {
        // approve USDC for lock fee
        vm.startPrank(liquidityProvider);
        IERC20(USDC).approve(address(liquidityFactory), liquidityFactory.liquidityLockFeeAmountBasic());

        // approve NFT transfer
        npm.approve(address(liquidityFactory), tokenId);

        // create lock
        address lock = liquidityFactory.createLock(POSITION_MANAGER, LiquidityLockFactory.LockType.BASIC, tokenId, 0);

        // verify lock creation
        LiquidityLockFactory.LockInfo[] memory userLocks = liquidityFactory.getUserLocks(liquidityProvider);
        assertEq(userLocks.length, 1);
        assertEq(userLocks[0].lockAddress, lock);
        assertEq(uint8(userLocks[0].lockType), uint8(LiquidityLockFactory.LockType.BASIC));
        assertEq(ILiquidity(lock).getStartTime(), block.timestamp);

        // verifying NFT transfer
        assertEq(npm.ownerOf(tokenId), lock);

        // verify fee transfer to collector

        assertEq(IERC20(USDC).balanceOf(feeCollector), liquidityFactory.liquidityLockFeeAmountBasic());

        // withdraw NFT

        ILiquidity(lock).withdraw(POSITION_MANAGER, tokenId);

        // verify NFT transfer back to owner

        assertEq(npm.ownerOf(tokenId), liquidityProvider);

        vm.stopPrank();
    }

    function testCreateBasicLockRevertIfNonOwnerWithdraw() public {
        // approve USDC for lock fee
        vm.startPrank(liquidityProvider);
        IERC20(USDC).approve(address(liquidityFactory), liquidityFactory.liquidityLockFeeAmountBasic());

        // approve NFT transfer
        npm.approve(address(liquidityFactory), tokenId);

        // create lock

        address lock = liquidityFactory.createLock(POSITION_MANAGER, LiquidityLockFactory.LockType.BASIC, tokenId, 0);

        // verify lock creation
        LiquidityLockFactory.LockInfo[] memory userLocks = liquidityFactory.getUserLocks(liquidityProvider);
        assertEq(userLocks.length, 1);
        assertEq(userLocks[0].lockAddress, lock);
        assertEq(uint8(userLocks[0].lockType), uint8(LiquidityLockFactory.LockType.BASIC));

        // verifying NFT transfer
        assertEq(npm.ownerOf(tokenId), lock);

        // verify fee transfer to collector
        assertEq(IERC20(USDC).balanceOf(feeCollector), liquidityFactory.liquidityLockFeeAmountBasic());

        vm.stopPrank();

        // try to withdraw NFT from another account

        vm.prank(randomUser);
        vm.expectRevert(BaseLiquidity.NotOwner.selector);
        ILiquidity(lock).withdraw(POSITION_MANAGER, tokenId);
    }

    function testCreateNormalLock() public {
        uint256 feeAmount = liquidityFactory.liquidityLockFeeAmountNormal();
        uint256 initialBalance = IERC20(USDC).balanceOf(feeCollector);

        // Approve USDC for lock fee
        vm.startPrank(liquidityProvider);
        IERC20(USDC).approve(address(liquidityFactory), liquidityFactory.liquidityLockFeeAmountNormal());

        // Approve NFT transfer
        npm.approve(address(liquidityFactory), tokenId);

        // Create lock
        address lock = liquidityFactory.createLock(
            POSITION_MANAGER, LiquidityLockFactory.LockType.NORMAL, tokenId, block.timestamp + LOCK_DURATION
        );

        // Verify lock creation
        LiquidityLockFactory.LockInfo[] memory userLocks = liquidityFactory.getUserLocks(liquidityProvider);
        assertEq(userLocks.length, 1);
        assertEq(userLocks[0].lockAddress, lock);
        assertEq(uint8(userLocks[0].lockType), uint8(LiquidityLockFactory.LockType.NORMAL));
        assertEq(ILiquidity(lock).getStartTime(), block.timestamp);

        // Verify NFT transfer
        assertEq(npm.ownerOf(tokenId), lock);

        // verify unlock time

        assertEq(ILiquidity(lock).getUnlockTime(), block.timestamp + LOCK_DURATION);

        // verify owner

        assertEq(ILiquidity(lock).getOwner(), liquidityProvider);

        // verify fee transfer to collector
        assertEq(IERC20(USDC).balanceOf(feeCollector), initialBalance + feeAmount, "Fee not transferred correctly");

        // withdraw NFT

        // fast forward time till unlockTime

        vm.warp(block.timestamp + LOCK_DURATION + 1);

        ILiquidity(lock).withdraw(POSITION_MANAGER, tokenId);

        // verify NFT transfer back to owner

        assertEq(npm.ownerOf(tokenId), liquidityProvider);

        vm.stopPrank();
    }

    function testCreateNormalLockRevertIfNonOwnerWithdraw() public {
        uint256 feeAmount = liquidityFactory.liquidityLockFeeAmountNormal();
        uint256 initialBalance = IERC20(USDC).balanceOf(feeCollector);

        // Approve USDC for lock fee
        vm.startPrank(liquidityProvider);
        IERC20(USDC).approve(address(liquidityFactory), liquidityFactory.liquidityLockFeeAmountNormal());

        // Approve NFT transfer
        npm.approve(address(liquidityFactory), tokenId);

        // Create lock
        address lock = liquidityFactory.createLock(
            POSITION_MANAGER, LiquidityLockFactory.LockType.NORMAL, tokenId, block.timestamp + LOCK_DURATION
        );

        // Verify lock creation
        LiquidityLockFactory.LockInfo[] memory userLocks = liquidityFactory.getUserLocks(liquidityProvider);

        assertEq(userLocks.length, 1);
        assertEq(userLocks[0].lockAddress, lock);
        assertEq(uint8(userLocks[0].lockType), uint8(LiquidityLockFactory.LockType.NORMAL));

        // Verify NFT transfer
        assertEq(npm.ownerOf(tokenId), lock);

        // verify unlock time

        assertEq(ILiquidity(lock).getUnlockTime(), block.timestamp + LOCK_DURATION);

        // verify owner

        assertEq(ILiquidity(lock).getOwner(), liquidityProvider);

        vm.stopPrank();

        // try to withdraw NFT from another account

        // fast forward time till unlock time

        vm.warp(block.timestamp + LOCK_DURATION + 1);

        vm.prank(randomUser);

        vm.expectRevert(BaseLiquidity.NotOwner.selector);
        ILiquidity(lock).withdraw(POSITION_MANAGER, tokenId);
    }

    function testNormalLockRevertOnEarlyWithdraw() public {
        uint256 feeAmount = liquidityFactory.liquidityLockFeeAmountNormal();
        uint256 initialBalance = IERC20(USDC).balanceOf(feeCollector);

        // Approve USDC for lock fee
        vm.startPrank(liquidityProvider);
        IERC20(USDC).approve(address(liquidityFactory), liquidityFactory.liquidityLockFeeAmountNormal());

        // Approve NFT transfer
        npm.approve(address(liquidityFactory), tokenId);

        // Create lock
        address lock = liquidityFactory.createLock(
            POSITION_MANAGER, LiquidityLockFactory.LockType.NORMAL, tokenId, block.timestamp + LOCK_DURATION
        );

        // Verify lock creation
        LiquidityLockFactory.LockInfo[] memory userLocks = liquidityFactory.getUserLocks(liquidityProvider);
        assertEq(userLocks.length, 1);
        assertEq(userLocks[0].lockAddress, lock);
        assertEq(uint8(userLocks[0].lockType), uint8(LiquidityLockFactory.LockType.NORMAL));

        // Verify NFT transfer
        assertEq(npm.ownerOf(tokenId), lock);

        // verify unlock time

        assertEq(ILiquidity(lock).getUnlockTime(), block.timestamp + LOCK_DURATION);

        // verify owner

        assertEq(ILiquidity(lock).getOwner(), liquidityProvider);

        // verify fee transfer to collector
        assertEq(IERC20(USDC).balanceOf(feeCollector), initialBalance + feeAmount, "Fee not transferred correctly");

        // try to withdraw early

        vm.expectPartialRevert(NormalLiquidity.TokenStillLocked.selector);
        ILiquidity(lock).withdraw(POSITION_MANAGER, tokenId);
    }

    function testFeeAdminUpdate() public {
        address newFeeAdmin = makeAddr("newFeeAdmin");
        vm.prank(feeAdmin);
        liquidityFactory.updateFeeAdmin(newFeeAdmin);
        assertEq(liquidityFactory.feeAdmin(), newFeeAdmin);
    }

    function testFeeAdminUpdateRevert() public {
        address newFeeAdmin = makeAddr("newFeeAdmin");
        vm.prank(liquidityProvider);
        vm.expectRevert(LiquidityLockFactory.NotFeeAdmin.selector);
        liquidityFactory.updateFeeAdmin(newFeeAdmin);
    }

    function testFeeAdminRevertOnZeroAddress() public {
        vm.prank(feeAdmin);
        vm.expectRevert(LiquidityLockFactory.NotValidAddress.selector);
        liquidityFactory.updateFeeAdmin(address(0));
    }

    function testFeeCollectorUpdate() public {
        address newFeeCollector = makeAddr("newFeeCollector");
        vm.prank(feeAdmin);
        liquidityFactory.updateFeeCollector(newFeeCollector);
        assertEq(liquidityFactory.feeCollector(), newFeeCollector);
    }

    function testFeeCollectorUpdateRevert() public {
        address newFeeCollector = makeAddr("newFeeCollector");
        vm.prank(liquidityProvider);
        vm.expectRevert(LiquidityLockFactory.NotFeeAdmin.selector);
        liquidityFactory.updateFeeCollector(newFeeCollector);
    }

    function testFeeCollectorRevertOnZeroAddress() public {
        vm.prank(feeAdmin);
        vm.expectRevert(LiquidityLockFactory.NotValidAddress.selector);
        liquidityFactory.updateFeeCollector(address(0));
    }

    function testFeeTokenUpdate() public {
        MockDugi newFeeToken = new MockDugi("newFeeToken", "NFT");
        vm.prank(feeAdmin);
        liquidityFactory.updateLockFeeToken(IERC20(address(newFeeToken)));
        assertEq(address(liquidityFactory.lockFeeToken()), address(newFeeToken));
    }

    function testFeeTokenUpdateRevert() public {
        MockDugi newFeeToken = new MockDugi("newFeeToken", "NFT");
        vm.prank(liquidityProvider);
        vm.expectRevert(LiquidityLockFactory.NotFeeAdmin.selector);
        liquidityFactory.updateLockFeeToken(IERC20(address(newFeeToken)));
    }

    function testFeeTokenUpdateRevertOnZeroAddress() public {
        vm.prank(feeAdmin);
        vm.expectRevert(LiquidityLockFactory.NotValidAddress.selector);
        liquidityFactory.updateLockFeeToken(IERC20(address(0)));
    }

    function testFeeAmountBasicUpdate() public {
        uint256 newFee = 100;
        vm.prank(feeAdmin);
        liquidityFactory.updatelockFeeAmountBasic(newFee);
        assertEq(liquidityFactory.liquidityLockFeeAmountBasic(), newFee);
    }

    function testFeeAmountBasicUpdateRevert() public {
        uint256 newFee = 100;
        vm.prank(liquidityProvider);
        vm.expectRevert(LiquidityLockFactory.NotFeeAdmin.selector);
        liquidityFactory.updatelockFeeAmountBasic(newFee);
    }

    function testFeeAmountNormalUpdate() public {
        uint256 newFee = 100;
        vm.prank(feeAdmin);
        liquidityFactory.updatelockFeeAmountNormal(newFee);
        assertEq(liquidityFactory.liquidityLockFeeAmountNormal(), newFee);
    }

    function testFeeAmountNormalUpdateRevert() public {
        uint256 newFee = 100;
        vm.prank(liquidityProvider);
        vm.expectRevert(LiquidityLockFactory.NotFeeAdmin.selector);
        liquidityFactory.updatelockFeeAmountNormal(newFee);
    }

     function testCreateBasicLockFuzz(
        address fuzzLiquidityProvider,
        uint256 fuzzTokenId,
        uint256 fuzzFeeAmount
    ) public {
        // bound and validate fuzz inputs
        vm.assume(fuzzLiquidityProvider != address(0));
        vm.assume(fuzzLiquidityProvider.code.length == 0);
        vm.assume(fuzzLiquidityProvider != liquidityFactory.feeCollector());
        vm.assume(fuzzLiquidityProvider != USDC_WHALE);

        fuzzTokenId = bound(fuzzTokenId, 1, 1_000_000);
        fuzzFeeAmount = bound(fuzzFeeAmount, 20e6, 1_000_000e6);

        //  provide funds with both tokens
        vm.startPrank(USDC_WHALE);
        IERC20(USDC).transfer(fuzzLiquidityProvider, 10_000e6);
        vm.stopPrank();

        // mint mock tokens to provider
        mockDugi.mint(fuzzLiquidityProvider, 10_000e18);

        vm.startPrank(fuzzLiquidityProvider);

        // approve tokens
        IERC20(USDC).approve(POSITION_MANAGER, type(uint256).max);
        mockDugi.approve(POSITION_MANAGER, type(uint256).max);

        // Create position
        (uint256 actualTokenId,,,) = npm.mint(
            INonfungiblePositionManager.MintParams({
                token0: USDC,
                token1: address(mockDugi),
                fee: POOL_FEE,
                tickLower: -887220,
                tickUpper: 887220,
                amount0Desired: 100e6,
                amount1Desired: 100e18,
                amount0Min: 0,
                amount1Min: 0,
                recipient: fuzzLiquidityProvider,
                deadline: block.timestamp + 1
            })
        );

        // Lock creation
        IERC20(USDC).approve(address(liquidityFactory), fuzzFeeAmount);
        npm.approve(address(liquidityFactory), actualTokenId);

        address lock = liquidityFactory.createLock(
            POSITION_MANAGER,
            LiquidityLockFactory.LockType.BASIC,
            actualTokenId,
            0
        );

        // Verifications
        LiquidityLockFactory.LockInfo[] memory userLocks = liquidityFactory.getUserLocks(fuzzLiquidityProvider);
        assertEq(userLocks.length, 1);
        assertEq(userLocks[0].lockAddress, lock);
        assertEq(uint8(userLocks[0].lockType), uint8(LiquidityLockFactory.LockType.BASIC));
        assertEq(npm.ownerOf(actualTokenId), lock);
        assertEq(ILiquidity(lock).getOwner(), fuzzLiquidityProvider);

        vm.stopPrank();
    }

    function testCreateNormalLockFuzz(
        address fuzzLiquidityProvider,
        uint256 fuzzTokenId,
        uint256 fuzzFeeAmount,
        uint256 fuzzUnlockTime
    ) public {
        // Bound and validate inputs
        vm.assume(fuzzLiquidityProvider != address(0));
        vm.assume(fuzzLiquidityProvider.code.length == 0);
        vm.assume(fuzzLiquidityProvider != liquidityFactory.feeCollector());
        vm.assume(fuzzLiquidityProvider != USDC_WHALE);

        fuzzTokenId = bound(fuzzTokenId, 1, 1_000_000);
        fuzzFeeAmount = bound(fuzzFeeAmount, liquidityFactory.liquidityLockFeeAmountNormal(), 1_000_000e6);
        fuzzUnlockTime = bound(fuzzUnlockTime, block.timestamp + 1 days, block.timestamp + 365 days);

        // Fund provider
        vm.startPrank(USDC_WHALE);
        IERC20(USDC).transfer(fuzzLiquidityProvider, 10_000e6);
        vm.stopPrank();

        mockDugi.mint(fuzzLiquidityProvider, 10_000e18);

        vm.startPrank(fuzzLiquidityProvider);

        // Create UniV3 position
        IERC20(USDC).approve(POSITION_MANAGER, type(uint256).max);
        mockDugi.approve(POSITION_MANAGER, type(uint256).max);

        (uint256 actualTokenId,,,) = npm.mint(
            INonfungiblePositionManager.MintParams({
                token0: USDC,
                token1: address(mockDugi),
                fee: POOL_FEE,
                tickLower: -887220,
                tickUpper: 887220,
                amount0Desired: 100e6,
                amount1Desired: 100e18,
                amount0Min: 0,
                amount1Min: 0,
                recipient: fuzzLiquidityProvider,
                deadline: block.timestamp + 1
            })
        );

        // Lock creation with proper approvals
        IERC20(USDC).approve(address(liquidityFactory), liquidityFactory.liquidityLockFeeAmountNormal());
        npm.approve(address(liquidityFactory), actualTokenId);

        address lock = liquidityFactory.createLock(
            POSITION_MANAGER,
            LiquidityLockFactory.LockType.NORMAL,
            actualTokenId,
            fuzzUnlockTime
        );

        // Verify lock state
        LiquidityLockFactory.LockInfo[] memory userLocks = liquidityFactory.getUserLocks(fuzzLiquidityProvider);
        assertEq(userLocks.length, 1);
        assertEq(userLocks[0].lockAddress, lock);
        assertEq(uint8(userLocks[0].lockType), uint8(LiquidityLockFactory.LockType.NORMAL));
        assertEq(npm.ownerOf(actualTokenId), lock);
        assertEq(ILiquidity(lock).getOwner(), fuzzLiquidityProvider);
        assertEq(ILiquidity(lock).getUnlockTime(), fuzzUnlockTime);

        vm.stopPrank();
    }
}
