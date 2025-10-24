// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title IGovProvider
 * @dev Interface for governance provider modules
 */
interface IGovProvider {
    struct GovDeploymentResult {
        address daoAddress;           // Main DAO contract address
        address adminPluginAddress;   // Admin plugin contract (if applicable)
        address tokenAddress;         // Governance token address
        string providerType;          // Provider identifier ("aragon", "simple", etc.)
        bytes extraData;              // Provider-specific data
    }
    
    struct GovConfig {
        string tokenName;
        string tokenSymbol;
        uint256 tokenSupply;
        address deployer;
        bytes providerSpecificConfig;
    }
    
    /**
     * @dev Deploy governance infrastructure
     * @param config Governance configuration parameters
     * @return result Deployment addresses and metadata
     */
    function deployGovernance(GovConfig memory config) 
        external 
        returns (GovDeploymentResult memory result);
    
    /**
     * @dev Get the provider type identifier
     */
    function getProviderType() external pure returns (string memory);
    
    /**
     * @dev Check if provider is available on current network
     */
    function isAvailable() external view returns (bool);
    
    /**
     * @dev Get required environment variables for this provider
     */
    function getRequiredEnvVars() external pure returns (string[] memory);
}