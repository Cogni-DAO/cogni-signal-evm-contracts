// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IGovProvider} from "../IGovProvider.sol";

/**
 * @title Simple DAO Provider
 * @dev Fallback provider using our existing SimpleDAO implementation
 */
contract SimpleDaoProvider is IGovProvider, Script {
    
    function deployGovernance(GovConfig memory config) 
        external 
        override 
        returns (GovDeploymentResult memory result) 
    {
        console2.log("Deploying Simple DAO...");
        
        // 1. Deploy governance token
        console2.log("  Deploying governance token...");
        CogniToken token = new CogniToken(
            config.tokenName,
            config.tokenSymbol,
            18, // decimals
            config.tokenSupply,
            config.deployer
        );
        
        // 2. Deploy Simple DAO
        console2.log("  Deploying Simple DAO...");
        SimpleDAO dao = new SimpleDAO(address(token));
        
        result = GovDeploymentResult({
            daoAddress: address(dao),
            adminPluginAddress: address(0), // SimpleDAO doesn't have admin plugin
            tokenAddress: address(token),
            providerType: "simple-dao",
            extraData: bytes("") // No extra data needed
        });
        
        console2.log("  Simple DAO deployment complete");
        console2.log("    DAO:", address(dao));
        console2.log("    Token:", address(token));
    }
    
    function getProviderType() external pure override returns (string memory) {
        return "simple-dao";
    }
    
    function isAvailable() public view override returns (bool) {
        return true; // Always available as fallback
    }
    
    function getRequiredEnvVars() external pure override returns (string[] memory) {
        string[] memory envVars = new string[](0);
        // SimpleDAO doesn't require additional env vars
        return envVars;
    }
}

/**
 * @title Simple ERC20 Token for DAO governance
 * @dev Copy from SetupDevChain.s.sol - should be extracted to shared location
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
 * @dev Copy from SetupDevChain.s.sol - should be extracted to shared location
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