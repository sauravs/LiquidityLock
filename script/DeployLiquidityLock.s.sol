// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import {LiquidityLockFactory} from "../src/LiquidityLockFactory.sol";
import {BasicLiquidity} from "../src/locks/BasicLiquidityLock.sol";
import {NormalLiquidity} from "../src/locks/NormalLiquidityLock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DeployLiquidityLock
 * @notice Deployment script for LiquidityLock project on Polygon
 */

/**
 * To execute this deployment script (run the following command)
 *
 *
 *  Step 1 : Create .env file in the root project folder and fill up the below keys
 *
 *  POLYGON_RPC_URL=https://polygon-mainnet.g.alchemy.com/v2/XXXXX
 * DEPLOYER_PVT_KEY=0xXXXXX
 * POLYGONSCAN_API_KEY=XXXXXX
 *
 * Step 2. Run `source .env` in your command line to load up env variables
 *
 *
 *  Step 3: forge script script/DeployLiquidityLock.s.sol:DeployLiquidityLock \
 *   --rpc-url $POLYGON_RPC_URL \
 *   --private-key $DEPLOYER_PVT_KEY \
 *   --broadcast \
 *   --verify \
 *   --etherscan-api-key $POLYGONSCAN_API_KEY \
 *   -vvv
 */
contract DeployLiquidityLock is Script {
    // Fee parameters - already set in the contract constructor
    address constant FEE_ADMIN = 0x80AB0Cb57106816b8eff9401418edB0Cb18ed5c7;
    address constant FEE_COLLECTOR = 0xd561f11d4ddb6E86B613F1dAaDE6a1e8ab0e6187;
    address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    uint256 constant BASIC_LOCK_FEE = 20 * 10 ** 6; // 20 USDC
    uint256 constant NORMAL_LOCK_FEE = 50 * 10 ** 6; // 50 USDC

    // Deployed contract addresses (to be filled during deployment)
    address public liquidityFactory;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PVT_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // deploy factory contract
        LiquidityLockFactory factory = new LiquidityLockFactory();
        liquidityFactory = address(factory);

        // log deployed addresses
        console.log("LiquidityLockFactory deployed at:", liquidityFactory);
        console.log("BasicLiquidity implementation at:", factory.basicImpl());
        console.log("NormalLiquidity implementation at:", factory.normalImpl());

        vm.stopBroadcast();

        // log verification information
        _logVerificationCommands(factory.basicImpl(), factory.normalImpl());
    }

    function _logVerificationCommands(address basicImpl, address normalImpl) internal view {
        console.log("\n=== VERIFICATION COMMANDS ===");
        console.log("Run these commands to verify your contracts on Polygonscan:");

        // verify Basic Implementation
        string memory verifyBasicCmd = string.concat(
            "forge verify-contract ",
            vm.toString(basicImpl),
            " src/locks/BasicLiquidityLock.sol:BasicLiquidity",
            " --chain-id 137",
            " --api-key $POLYGONSCAN_API_KEY"
        );

        // verify Normal Implementation
        string memory verifyNormalCmd = string.concat(
            "forge verify-contract ",
            vm.toString(normalImpl),
            " src/locks/NormalLiquidityLock.sol:NormalLiquidity",
            " --chain-id 137",
            " --api-key $POLYGONSCAN_API_KEY"
        );

        // verify Factory (no constructor args needed as implementation creation happens inside constructor)
        string memory verifyFactoryCmd = string.concat(
            "forge verify-contract ",
            vm.toString(liquidityFactory),
            " src/LiquidityLockFactory.sol:LiquidityLockFactory",
            " --chain-id 137",
            " --api-key $POLYGONSCAN_API_KEY"
        );

        console.log("1. Verify BasicLiquidity:");
        console.log(verifyBasicCmd);

        console.log("\n2. Verify NormalLiquidity:");
        console.log(verifyNormalCmd);

        console.log("\n3. Verify LiquidityLockFactory:");
        console.log(verifyFactoryCmd);
    }
}
