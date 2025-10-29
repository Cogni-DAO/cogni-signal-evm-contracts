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
 * - WALLET_PRIVATE_KEY: Private key for funded Sepolia wallet
 * - EVM_RPC_URL: Sepolia RPC endpoint
 * 
 * Optional:
 * - GOV_PROVIDER: Governance provider ("aragon-osx", "simple") - defaults to "aragon-osx"
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
        address votingPlugin;       // Voting plugin address
        address cogniSignal;
        address deployer;
        uint256 chainId;
        string tokenName;
        string tokenSymbol;
        string govProviderType;     // Provider type used
    }
    
    function run() external returns (DeploymentResult memory result) {
        // Fork real chain state
        vm.createSelectFork(vm.envString("EVM_RPC_URL"));
        
        // Validate environment
        uint256 deployerPrivateKey = uint256(vm.envBytes32("WALLET_PRIVATE_KEY"));
        address deployer = vm.addr(deployerPrivateKey);
        
        // Configuration
        string memory govProviderEnv = vm.envOr("GOV_PROVIDER", string("aragon-osx"));
        string memory tokenName = vm.envOr("TOKEN_NAME", string("Cogni Governance Token"));
        string memory tokenSymbol = vm.envOr("TOKEN_SYMBOL", string("CGT"));
        uint256 tokenSupply = vm.envOr("TOKEN_SUPPLY", uint256(1000000 * 10**18)); // 1M tokens
        address tokenInitialHolder = vm.envAddress("TOKEN_INITIAL_HOLDER");
        
        console2.log("=== Development Chain Setup (Modular Governance) ===");
        
        // Check deployer balance on real chain
        uint256 balance = deployer.balance;
        require(balance >= 0.01 ether, "Insufficient ETH balance for deployment");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Create governance provider
        GovProviderFactory.ProviderType providerType = GovProviderFactory.parseProviderType(govProviderEnv);
        IGovProvider govProvider = GovProviderFactory.createProvider(providerType);
        
        // 2. Deploy governance infrastructure  
        IGovProvider.GovConfig memory govConfig = IGovProvider.GovConfig({
            tokenName: tokenName,
            tokenSymbol: tokenSymbol,
            tokenSupply: tokenSupply,
            deployer: deployer,
            tokenInitialHolder: tokenInitialHolder,
            providerSpecificConfig: _getProviderSpecificConfig(providerType, tokenInitialHolder)
        });
        
        IGovProvider.GovDeploymentResult memory govResult = govProvider.deployGovernance(govConfig);
        
        // Verify governance infrastructure was actually deployed
        mustHaveCode(govResult.daoAddress, "DAO");
        mustHaveCode(govResult.tokenAddress, "Token");
        // Note: Admin plugin may not have code until applyInstallation is called
        
        // 3. Deploy CogniSignal Contract
        CogniSignal cogniSignal = new CogniSignal(govResult.daoAddress);
        mustHaveCode(address(cogniSignal), "CogniSignal");
        
        vm.stopBroadcast();
        
        // Prepare result
        result = DeploymentResult({
            token: govResult.tokenAddress,
            dao: govResult.daoAddress,
            votingPlugin: govResult.votingPluginAddress,
            cogniSignal: address(cogniSignal),
            deployer: deployer,
            chainId: block.chainid,
            tokenName: tokenName,
            tokenSymbol: tokenSymbol,
            govProviderType: govResult.providerType
        });
        
        // Print deployment summary and save environment variables
        _printDeploymentSummary(result);
        _saveEnvironmentVariablesToFile(result);
        _printFinalInstructions(result);
        
        return result;
    }
    
    function _printDeploymentSummary(DeploymentResult memory result) internal view {
        console2.log("");
        console2.log("DEPLOYMENT COMPLETE!");
        console2.log("========================");
        console2.log("Governance Type:", result.govProviderType);
        console2.log("ERC20 Token:    ", result.token);
        console2.log("DAO:           ", result.dao);
        if (result.votingPlugin != address(0)) {
            console2.log("Voting Plugin: ", result.votingPlugin);
        }
        console2.log("CogniSignal:   ", result.cogniSignal);
        console2.log("Chain ID:      ", result.chainId);
        console2.log("Deployer:      ", result.deployer);
        console2.log("");
    }
    
    function _printFinalInstructions(DeploymentResult memory result) internal view {
        console2.log("");
        console2.log("SETUP COMPLETE!");
        console2.log("===============");
        console2.log("Copy the environment variables from .env.", result.tokenSymbol);
        console2.log("to the bottom of your cogni-git-admin .env file");
        console2.log("");
        console2.log("IMPORTANT: Setup Alchemy webhook monitoring:");
        console2.log("  Contract:", result.cogniSignal);
        console2.log("  Point to your cogni-git-admin `<deployment_url>/api/v1/webhooks/onchain/cogni-signal`");
        console2.log("");
        console2.log("Then run: npm run e2e");
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
            
            "## Chain Configuration - Copy/paste from smart contract repo script\n",
            "WALLET_PRIVATE_KEY=", vm.envString("WALLET_PRIVATE_KEY"), "     # Used by cogni-git-admin E2E tests ONLY. App does not use the key.\n",
            "EVM_RPC_URL=", vm.envString("EVM_RPC_URL"), "\n",
            "SIGNAL_CONTRACT=", vm.toString(result.cogniSignal), "\n",
            "DAO_ADDRESS=", vm.toString(result.dao), "\n",
            "CHAIN_ID=", vm.toString(result.chainId), "\n"
        );
        
        // Add voting plugin if available
        if (result.votingPlugin != address(0)) {
            envContent = string.concat(
                envContent,
                "ARAGON_VOTING_PLUGIN_CONTRACT=", vm.toString(result.votingPlugin), "\n"
            );
        } else {
            envContent = string.concat(
                envContent,
                "# ARAGON_VOTING_PLUGIN_CONTRACT=  # Not applicable for ", result.govProviderType, "\n"
            );
        }
        
        envContent = string.concat(
            envContent,
            "\n## Optional Extras\n",
            "GOVERNANCE_TOKEN=", vm.toString(result.token), "\n",
            "TOKEN_NAME=", result.tokenName, "\n",
            "TOKEN_SYMBOL=", result.tokenSymbol, "\n",
            "GOV_PROVIDER=", result.govProviderType, "\n",
            "DEPLOYER_ADDRESS=", vm.toString(result.deployer), "\n"
        );
        
        // Write to file
        vm.writeFile(filename, envContent);
        console2.log("Environment variables saved to:", filename);
    }
    
    function _getProviderSpecificConfig(GovProviderFactory.ProviderType providerType, address tokenInitialHolder) internal view returns (bytes memory) {
        if (providerType == GovProviderFactory.ProviderType.ARAGON) {
            // Load Aragon addresses from official artifacts for current network
            address daoFactory = _getAragonDAOFactory();
            address psp = _getAragonPSP();
            address tokenVotingRepo = _getAragonTokenVotingRepo();
            
            // Pack only Aragon-specific addresses
            return abi.encode(daoFactory, psp, tokenVotingRepo);
        } else {
            // Other providers don't need specific addresses
            return abi.encode();
        }
    }
    
    function _getAragonDAOFactory() internal view returns (address) {
        if (block.chainid == 11155111) { // Sepolia
            return 0xB815791c233807D39b7430127975244B36C19C8e;
        }
        revert("Unsupported network for Aragon");
    }
    
    function _getAragonPSP() internal view returns (address) {
        if (block.chainid == 11155111) { // Sepolia
            return 0xC24188a73dc09aA7C721f96Ad8857B469C01dC9f;
        }
        revert("Unsupported network for Aragon");
    }
    
    function _getAragonTokenVotingRepo() internal view returns (address) {
        if (block.chainid == 11155111) { // Sepolia
            return 0x424F4cA6FA9c24C03f2396DF0E96057eD11CF7dF;
        }
        revert("Unsupported network for Aragon");
    }
}