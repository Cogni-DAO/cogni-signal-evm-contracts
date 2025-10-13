// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Deploy} from "./Deploy.s.sol";
import {CogniSignal} from "../src/CogniSignal.sol";
import {IGovProvider} from "./gov_providers/IGovProvider.sol";
import {GovProviderFactory} from "./gov_providers/GovProviderFactory.sol";


/**
 * @title Development Chain Setup Script
 * @dev Deploys complete development stack: ERC20 → DAO → CogniSignal
 * 
 * Required Environment Variables:
 * - DEV_WALLET_PRIVATE_KEY: Private key for funded Sepolia wallet
 * - RPC_URL: Sepolia RPC endpoint
 * 
 * Optional:
 * - GOV_PROVIDER: Governance provider ("aragon", "simple", or "auto") - defaults to "auto"
 * - TOKEN_NAME: ERC20 token name (default: "Cogni Governance Token")
 * - TOKEN_SYMBOL: ERC20 token symbol (default: "CGT")
 * - TOKEN_SUPPLY: Initial token supply (default: 1000000000000000000000000 = 1M tokens)
 */
contract SetupDevChain is Script {
    function mustHaveCode(address a, string memory tag) internal view {
        require(a.code.length > 0, string.concat("no code: ", tag));
    }
    
    struct DeploymentResult {
        address token;
        address dao;
        address adminPlugin;        // Admin plugin address (if applicable)
        address cogniSignal;
        address deployer;
        uint256 chainId;
        string tokenName;
        string tokenSymbol;
        string govProviderType;     // Provider type used
    }
    
    function run() external returns (DeploymentResult memory result) {
        // Fork real chain state
        vm.createSelectFork(vm.envString("RPC_URL"));
        
        // Validate environment
        uint256 deployerPrivateKey = uint256(vm.envBytes32("DEV_WALLET_PRIVATE_KEY"));
        address deployer = vm.addr(deployerPrivateKey);
        
        // Configuration
        string memory govProviderEnv = vm.envOr("GOV_PROVIDER", string("aragon"));
        string memory tokenName = vm.envOr("TOKEN_NAME", string("Cogni Governance Token"));
        string memory tokenSymbol = vm.envOr("TOKEN_SYMBOL", string("CGT"));
        uint256 tokenSupply = vm.envOr("TOKEN_SUPPLY", uint256(1000000 * 10**18)); // 1M tokens
        
        console2.log("=== Development Chain Setup (Modular Governance) ===");
        console2.log("Deployer address:", deployer);
        console2.log("Chain ID:", block.chainid);
        console2.log("Gov Provider:", govProviderEnv);
        console2.log("Token Name:", tokenName);
        console2.log("Token Symbol:", tokenSymbol);
        console2.log("Initial Supply:", tokenSupply / 10**18, "tokens");
        console2.log("");
        
        // Check deployer balance on real chain
        uint256 balance = deployer.balance;
        console2.log("Deployer balance:", balance / 1 ether, "ETH");
        require(balance >= 0.01 ether, "Insufficient ETH balance for deployment");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Create governance provider
        GovProviderFactory.ProviderType providerType = GovProviderFactory.parseProviderType(govProviderEnv);
        IGovProvider govProvider = GovProviderFactory.createProvider(providerType);
        
        // 2. Deploy governance infrastructure
        console2.log("Deploying governance infrastructure...");
        IGovProvider.GovConfig memory govConfig = IGovProvider.GovConfig({
            tokenName: tokenName,
            tokenSymbol: tokenSymbol,
            tokenSupply: tokenSupply,
            deployer: deployer,
            providerSpecificConfig: bytes("")
        });
        
        IGovProvider.GovDeploymentResult memory govResult = govProvider.deployGovernance(govConfig);
        
        // Verify governance infrastructure was actually deployed
        mustHaveCode(govResult.daoAddress, "DAO");
        mustHaveCode(govResult.tokenAddress, "Token");
        // Note: Admin plugin may not have code until applyInstallation is called
        
        // 3. Deploy CogniSignal Contract
        console2.log("Deploying CogniSignal contract...");
        CogniSignal cogniSignal = new CogniSignal(govResult.daoAddress);
        console2.log("CogniSignal deployed:", address(cogniSignal));
        mustHaveCode(address(cogniSignal), "CogniSignal");
        
        vm.stopBroadcast();
        
        // Prepare result
        result = DeploymentResult({
            token: govResult.tokenAddress,
            dao: govResult.daoAddress,
            adminPlugin: govResult.adminPluginAddress,
            cogniSignal: address(cogniSignal),
            deployer: deployer,
            chainId: block.chainid,
            tokenName: tokenName,
            tokenSymbol: tokenSymbol,
            govProviderType: govResult.providerType
        });
        
        // Print deployment summary and environment variables
        _printDeploymentSummary(result);
        _printEnvironmentVariables(result);
        _saveEnvironmentVariablesToFile(result);
        
        return result;
    }
    
    function _printDeploymentSummary(DeploymentResult memory result) internal view {
        console2.log("");
        console2.log("DEPLOYMENT COMPLETE!");
        console2.log("========================");
        console2.log("Governance Type:", result.govProviderType);
        console2.log("ERC20 Token:    ", result.token);
        console2.log("DAO:           ", result.dao);
        if (result.adminPlugin != address(0)) {
            console2.log("Admin Plugin:  ", result.adminPlugin);
        }
        console2.log("CogniSignal:   ", result.cogniSignal);
        console2.log("Chain ID:      ", result.chainId);
        console2.log("Deployer:      ", result.deployer);
        console2.log("");
    }
    
    function _printEnvironmentVariables(DeploymentResult memory result) internal view {
        console2.log("ENVIRONMENT VARIABLES FOR COGNI-GIT-ADMIN:");
        console2.log("==============================================");
        console2.log("# Copy these to your cogni-git-admin .env file");
        console2.log("");
        console2.log("# Chain Configuration");
        console2.log("COGNI_CHAIN_ID=", vm.toString(result.chainId));
        console2.log("E2E_SEPOLIA_RPC_URL=", vm.envString("RPC_URL"));
        console2.log("");
        console2.log("# Contract Addresses");
        console2.log("COGNI_SIGNAL_CONTRACT=", vm.toString(result.cogniSignal));
        console2.log("E2E_COGNISIGNAL_CONTRACT=", vm.toString(result.cogniSignal));
        console2.log("COGNI_ALLOWED_DAO=", _toLowerCase(result.dao));
        console2.log("E2E_DAO_ADDRESS=", vm.toString(result.dao));
        
        // Print admin plugin address if available (for Aragon OSx)
        if (result.adminPlugin != address(0)) {
            console2.log("E2E_ADMIN_PLUGIN_CONTRACT=", vm.toString(result.adminPlugin));
        } else {
            console2.log("# E2E_ADMIN_PLUGIN_CONTRACT=  # Not applicable for ", result.govProviderType);
        }
        console2.log("");
        console2.log("# Token Information");
        console2.log("E2E_GOVERNANCE_TOKEN=", vm.toString(result.token));
        console2.log("E2E_TOKEN_NAME=", result.tokenName);
        console2.log("E2E_TOKEN_SYMBOL=", result.tokenSymbol);
        console2.log("");
        console2.log("# Development Wallet");
        console2.log("E2E_DEPLOYER_ADDRESS=", vm.toString(result.deployer));
        console2.log("");
    }
    
    function _toLowerCase(address addr) internal pure returns (string memory) {
        bytes memory data = abi.encodePacked(addr);
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
    
    function _saveEnvironmentVariablesToFile(DeploymentResult memory result) internal {
        string memory filename = string.concat(".env.", result.tokenSymbol);
        console2.log("Saving environment variables to:", filename);
        
        string memory envContent = string.concat(
            "# Deployment Environment Variables\n",
            "# Generated by SetupDevChain.s.sol at ", vm.toString(block.timestamp), "\n\n",
            
            "# Chain Configuration\n",
            "COGNI_CHAIN_ID=", vm.toString(result.chainId), "\n",
            "E2E_SEPOLIA_RPC_URL=", vm.envString("RPC_URL"), "\n\n",
            
            "# Contract Addresses\n",
            "COGNI_SIGNAL_CONTRACT=", vm.toString(result.cogniSignal), "\n",
            "E2E_COGNISIGNAL_CONTRACT=", vm.toString(result.cogniSignal), "\n",
            "COGNI_ALLOWED_DAO=", _toLowerCase(result.dao), "\n",
            "E2E_DAO_ADDRESS=", vm.toString(result.dao), "\n"
        );
        
        // Add admin plugin if available
        if (result.adminPlugin != address(0)) {
            envContent = string.concat(
                envContent,
                "E2E_ADMIN_PLUGIN_CONTRACT=", vm.toString(result.adminPlugin), "\n"
            );
        } else {
            envContent = string.concat(
                envContent,
                "# E2E_ADMIN_PLUGIN_CONTRACT=  # Not applicable for ", result.govProviderType, "\n"
            );
        }
        
        envContent = string.concat(
            envContent,
            "\n# Token Information\n",
            "E2E_GOVERNANCE_TOKEN=", vm.toString(result.token), "\n",
            "E2E_TOKEN_NAME=", result.tokenName, "\n",
            "E2E_TOKEN_SYMBOL=", result.tokenSymbol, "\n\n",
            
            "# Development Wallet\n",
            "E2E_DEPLOYER_ADDRESS=", vm.toString(result.deployer), "\n\n",
            
            "# Governance Provider Info\n",
            "GOV_PROVIDER_TYPE=", result.govProviderType, "\n"
        );
        
        // Write to file
        vm.writeFile(filename, envContent);
        console2.log("Environment variables saved to:", filename);
    }
}