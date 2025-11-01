// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {FaucetMinter} from "../src/FaucetMinter.sol";

/**
 * @title Deploy Faucet Minter Script
 * @dev Deploys a token faucet for existing or new DAO setups
 * 
 * Required Environment Variables:
 * - WALLET_PRIVATE_KEY: Private key for deployment
 * - EVM_RPC_URL: RPC endpoint
 * - DAO_ADDRESS: Address of the DAO that will control the faucet
 * - TOKEN_ADDRESS: Address of the governance token to mint
 * 
 * Optional:
 * - FAUCET_AMOUNT_PER_CLAIM: Tokens to mint per claim (default: 1e18)
 * - FAUCET_GLOBAL_CAP: Maximum total tokens faucet can mint (default: 1000000e18)
 */
contract DeployFaucetMinter is Script {
    function run() external returns (address faucetAddress) {
        // Load configuration
        uint256 deployerPrivateKey = uint256(vm.envBytes32("WALLET_PRIVATE_KEY"));
        address daoAddress = vm.envAddress("DAO_ADDRESS");
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        
        uint256 amountPerClaim = vm.envOr("FAUCET_AMOUNT_PER_CLAIM", uint256(1e18)); // 1 token
        uint256 globalCap = vm.envOr("FAUCET_GLOBAL_CAP", uint256(1000000e18)); // 1M tokens
        
        console2.log("=== Deploying FaucetMinter ===");
        console2.log("DAO Address:", daoAddress);
        console2.log("Token Address:", tokenAddress);
        console2.log("Amount Per Claim:", amountPerClaim);
        console2.log("Global Cap:", globalCap);
        
        // Validate inputs
        require(daoAddress != address(0), "DAO address cannot be zero");
        require(tokenAddress != address(0), "Token address cannot be zero");
        require(daoAddress.code.length > 0, "DAO address has no code");
        require(tokenAddress.code.length > 0, "Token address has no code");
        require(amountPerClaim > 0, "Amount per claim must be > 0");
        require(globalCap >= amountPerClaim, "Global cap must be >= amount per claim");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the faucet
        FaucetMinter faucet = new FaucetMinter(
            daoAddress,
            tokenAddress,
            amountPerClaim,
            globalCap
        );
        
        vm.stopBroadcast();
        
        faucetAddress = address(faucet);
        
        console2.log("FaucetMinter deployed at:", faucetAddress);
        console2.log("");
        console2.log("Next steps:");
        console2.log("1. Grant MINT_PERMISSION_ID to the faucet:");
        console2.log("   forge script GrantMintToFaucet --rpc-url $EVM_RPC_URL --broadcast");
        console2.log("2. Optionally grant CONFIG_PERMISSION and PAUSE_PERMISSION for DAO control");
        console2.log("");
        console2.log("Environment variables for UI:");
        console2.log("FAUCET_ADDRESS=%s", faucetAddress);
        console2.log("FAUCET_AMOUNT=%s", amountPerClaim);
        
        return faucetAddress;
    }
}