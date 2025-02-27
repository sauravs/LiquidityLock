# NFT Liquidity Lock Platform

## Overview
A decentralized platform for locking NFT liquidity with customizable time-based restrictions. The platform allows users to lock their NFTs in smart contracts with two different locking mechanisms: Basic (immediate withdrawal) and Normal (time-locked).

## Key Features
- Two types of liquidity locks:
  - Basic Lock: Immediate withdrawal capability
  - Normal Lock: Time-restricted withdrawal
- Clone Factory pattern for deploying lock contracts
- Fee-based lock creation system
- Upgradeable contract architecture
- Owner-based access control
- Safe NFT handling with ERC721 standards

## Contract Architecture
- `LiquidityLockFactory`: Main factory contract for creating lock instances
- `BaseLiquidity`: Abstract base contract with core locking logic
- `BasicLiquidityLock`: Implementation for immediate withdrawal locks
- `NormalLiquidityLock`: Implementation for time-restricted locks
- `ILiquidity`: Interface defining core locking functionality

## How it Works
1. Users interact with the `LiquidityLockFactory` to create new locks
2. Pay creation fee in USDC (configurable)
3. Choose between Basic and Normal lock types
4. NFTs are held in individual clone contracts
5. Owners can withdraw based on lock type rules:
   - Basic: Withdraw anytime
   - Normal: Must wait until unlock time

## Technical Details
- Solidity Version: 0.8.24
- Uses OpenZeppelin contracts
- Implements Clone Factory pattern
- Uses USDC for fee payments
- Supports ERC721 standard NFTs

## Fee Structure
- Basic Lock: 20 USDC
- Normal Lock: 50 USDC
- Configurable by fee admin

## Usage
To create a lock:
1. Approve NFT transfer to factory
2. Pay required USDC fee
3. Call `createLock` with:
   - NFT contract address
   - Lock type (BASIC/NORMAL)
   - Token ID
   - Unlock time (for NORMAL locks)

## Security Features
- ReentrancyGuard implementation
- Address validation checks
- Protected initializers
- Admin-controlled fee parameters
- 100% test coverage
- Fuzz runs verfied for important functions for 256 runs


 


