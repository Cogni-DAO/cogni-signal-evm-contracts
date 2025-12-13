// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {CogniSignal} from "../src/CogniSignal.sol";
import {FaucetMinter} from "../src/FaucetMinter.sol";
import {IGovProvider} from "./gov_providers/IGovProvider.sol";
import {GovProviderFactory} from "./gov_providers/GovProviderFactory.sol";


/**
 * @title Development Chain Setup Script
 * @dev Deploys complete development stack: ERC20 → DAO → CogniSignal
 *
 * Required Environment Variables:
 * - WALLET_PRIVATE_KEY: Private key for funded wallet
 * - EVM_RPC_URL: RPC endpoint for target network
 * - CHAIN_ID: Target network chain ID (e.g., 8453 for Base, 11155111 for Sepolia)
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
        address faucet;            // FaucetMinter address (unauthorized until DAO proposal)
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
        require(balance >= 0.00001 ether, "Insufficient ETH balance for deployment");
        
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
        
        // 4. Deploy FaucetMinter (unauthorized until DAO proposal grants permissions)
        uint256 amountPerClaim = vm.envOr("FAUCET_AMOUNT_PER_CLAIM", uint256(1e18)); // 1 full token
        uint256 globalCap = vm.envOr("FAUCET_GLOBAL_CAP", uint256(1000000e18)); // 1M full tokens
        FaucetMinter faucet = new FaucetMinter(
            govResult.daoAddress,
            govResult.tokenAddress,
            amountPerClaim,
            globalCap
        );
        mustHaveCode(address(faucet), "FaucetMinter");
        
        vm.stopBroadcast();
        
        // Prepare result
        result = DeploymentResult({
            token: govResult.tokenAddress,
            dao: govResult.daoAddress,
            votingPlugin: govResult.votingPluginAddress,
            cogniSignal: address(cogniSignal),
            faucet: address(faucet),
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
        console2.log("Faucet:        ", result.faucet, " (UNAUTHORIZED - needs DAO proposal)");
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
            "UNAUTHORIZED_GOVTOKEN_FAUCET=", vm.toString(result.faucet), "     # Requires DAO proposal to grant MINT_PERMISSION\n",
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
        return _getAragonAddress("DAOFactory");
    }

    function _getAragonPSP() internal view returns (address) {
        return _getAragonAddress("PluginSetupProcessor");
    }

    function _getAragonTokenVotingRepo() internal view returns (address) {
        return _getAragonAddress("TokenVotingRepo");
    }

    function _getAragonAddress(string memory component) internal view returns (address addr) {
        uint256 chainId = block.chainid;
        bytes32 componentHash = keccak256(bytes(component));

        // Sepolia (11155111)
        if (chainId == 11155111) {
            if (componentHash == keccak256("DAOFactory")) addr = 0xB815791c233807D39b7430127975244B36C19C8e;
            else if (componentHash == keccak256("PluginSetupProcessor")) addr = 0xC24188a73dc09aA7C721f96Ad8857B469C01dC9f;
            else if (componentHash == keccak256("TokenVotingRepo")) addr = 0x424F4cA6FA9c24C03f2396DF0E96057eD11CF7dF;
        }
        // Base Mainnet (8453)
        else if (chainId == 8453) {
            if (componentHash == keccak256("DAOFactory")) addr = 0xcc602EA573a42eBeC290f33F49D4A87177ebB8d2;
            else if (componentHash == keccak256("PluginSetupProcessor")) addr = 0x91a851E9Ed7F2c6d41b15F76e4a88f5A37067cC9;
            else if (componentHash == keccak256("TokenVotingRepo")) addr = 0x2532570DcFb749A7F976136CC05648ef2a0f60b0;
        }
        // Base Sepolia (84532)
        else if (chainId == 84532) {
            if (componentHash == keccak256("DAOFactory")) addr = 0x016CBa9bd729C30b16849b2c52744447767E9dab;
            else if (componentHash == keccak256("PluginSetupProcessor")) addr = 0xd97D409Ca645b108468c26d8506f3a4Bf9D0BE81;
            else if (componentHash == keccak256("TokenVotingRepo")) addr = 0xdEbcF8779495a62156c6d1416628F60525984e9d;
        }

        require(addr != address(0), string.concat("Aragon OSx ", component, " not available on this network"));

        // Preflight: verify contract code exists
        require(addr.code.length > 0, string.concat("No code at Aragon ", component, " address"));
    }
}