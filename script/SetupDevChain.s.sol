// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Deploy} from "./Deploy.s.sol";
import {CogniSignal} from "../src/CogniSignal.sol";

/**
 * @title Simple ERC20 Token for DAO governance
 * @dev Mints initial supply to deployer for testing purposes
 */
contract CogniToken is ERC20 {
    uint8 private _decimals;
    
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_,
        uint256 initialSupply,
        address recipient
    ) ERC20(name, symbol) {
        _decimals = decimals_;
        _mint(recipient, initialSupply);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}

/**
 * @title Simple DAO for CogniSignal testing
 * @dev Minimal DAO implementation with basic governance and execution
 */
contract SimpleDAO {
    address public owner;
    ERC20 public token;
    
    struct Action {
        address to;
        uint256 value;
        bytes data;
    }
    
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "SimpleDAO: caller is not owner");
        _;
    }
    
    constructor(address _token) {
        owner = msg.sender;
        token = ERC20(_token);
    }
    
    /**
     * @dev Execute actions directly (for testing/development)
     * @param actions Array of actions to execute
     * @param allowFailureMap Bitmap indicating which actions are allowed to fail
     */
    function execute(Action[] calldata actions, uint256 allowFailureMap) 
        external 
        onlyOwner 
        returns (bytes[] memory results) 
    {
        uint256 actionsLength = actions.length;
        results = new bytes[](actionsLength);
        
        for (uint256 i = 0; i < actionsLength; ) {
            Action memory action = actions[i];
            bool isAllowedToFail = (allowFailureMap >> i) & 1 == 1;
            
            (bool success, bytes memory result) = action.to.call{value: action.value}(action.data);
            
            if (!success && !isAllowedToFail) {
                revert("SimpleDAO: action execution failed");
            }
            
            results[i] = result;
            
            unchecked {
                ++i;
            }
        }
        
        emit ProposalExecuted(block.timestamp, true);
    }
    
    /**
     * @dev Transfer ownership to new address
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "SimpleDAO: new owner is zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @title Development Chain Setup Script
 * @dev Deploys complete development stack: ERC20 → DAO → CogniSignal
 * 
 * Required Environment Variables:
 * - DEV_WALLET_PRIVATE_KEY: Private key for funded Sepolia wallet
 * - RPC_URL: Sepolia RPC endpoint
 * 
 * Optional:
 * - TOKEN_NAME: ERC20 token name (default: "Cogni Governance Token")
 * - TOKEN_SYMBOL: ERC20 token symbol (default: "CGT")
 * - TOKEN_SUPPLY: Initial token supply (default: 1000000000000000000000000 = 1M tokens)
 */
contract SetupDevChain is Script {
    struct DeploymentResult {
        address token;
        address dao;
        address cogniSignal;
        address deployer;
        uint256 chainId;
        string tokenName;
        string tokenSymbol;
    }
    
    function run() external returns (DeploymentResult memory result) {
        // Validate environment
        uint256 deployerPrivateKey = vm.envUint("DEV_WALLET_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Token configuration
        string memory tokenName = vm.envOr("TOKEN_NAME", string("Cogni Governance Token"));
        string memory tokenSymbol = vm.envOr("TOKEN_SYMBOL", string("CGT"));
        uint256 tokenSupply = vm.envOr("TOKEN_SUPPLY", uint256(1000000 * 10**18)); // 1M tokens
        
        console2.log("=== Development Chain Setup ===");
        console2.log("Deployer address:", deployer);
        console2.log("Chain ID:", block.chainid);
        console2.log("Token Name:", tokenName);
        console2.log("Token Symbol:", tokenSymbol);
        console2.log("Initial Supply:", tokenSupply / 10**18, "tokens");
        console2.log("");
        
        // Check deployer balance
        uint256 balance = deployer.balance;
        require(balance >= 0.04 ether, "Insufficient ETH balance for deployment");
        console2.log("Deployer balance:", balance / 1 ether, "ETH");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy ERC20 Token
        console2.log("Deploying ERC20 token...");
        CogniToken token = new CogniToken(
            tokenName,
            tokenSymbol,
            18, // decimals
            tokenSupply,
            deployer // mint to deployer
        );
        console2.log("Token deployed:", address(token));
        
        // 2. Deploy Simple DAO
        console2.log("Deploying Simple DAO...");
        SimpleDAO dao = new SimpleDAO(address(token));
        console2.log("DAO deployed:", address(dao));
        
        // 3. Deploy CogniSignal Contract using existing Deploy script
        console2.log("Deploying CogniSignal contract...");
        
        // Set DAO_ADDRESS for Deploy script
        vm.setEnv("DAO_ADDRESS", vm.toString(address(dao)));
        
        // Create and run Deploy script without nested broadcast
        Deploy deployScript = new Deploy();
        CogniSignal cogniSignal = deployScript.runWithoutBroadcast();
        console2.log("CogniSignal deployed:", address(cogniSignal));
        
        vm.stopBroadcast();
        
        // Prepare result
        result = DeploymentResult({
            token: address(token),
            dao: address(dao),
            cogniSignal: address(cogniSignal),
            deployer: deployer,
            chainId: block.chainid,
            tokenName: tokenName,
            tokenSymbol: tokenSymbol
        });
        
        // Print deployment summary and environment variables
        _printDeploymentSummary(result);
        _printEnvironmentVariables(result);
        
        return result;
    }
    
    function _printDeploymentSummary(DeploymentResult memory result) internal view {
        console2.log("");
        console2.log("DEPLOYMENT COMPLETE!");
        console2.log("========================");
        console2.log("ERC20 Token:    ", result.token);
        console2.log("DAO:           ", result.dao);
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
        console2.log("");
        console2.log("# Token Information");
        console2.log("E2E_GOVERNANCE_TOKEN=", vm.toString(result.token));
        console2.log("E2E_TOKEN_NAME=", result.tokenName);
        console2.log("E2E_TOKEN_SYMBOL=", result.tokenSymbol);
        console2.log("");
        console2.log("# Development Wallet (KEEP SECURE!)");
        console2.log("E2E_TEST_WALLET_PRIVATE_KEY=", vm.envString("DEV_WALLET_PRIVATE_KEY"));
        console2.log("E2E_DEPLOYER_ADDRESS=", vm.toString(result.deployer));
        console2.log("");
        console2.log("NOTE: The DAO owner is set to the deployer address.");
        console2.log("For production, transfer ownership to a multisig or governance contract.");
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
}