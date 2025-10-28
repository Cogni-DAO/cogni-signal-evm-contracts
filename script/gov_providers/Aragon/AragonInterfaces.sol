// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title Aragon OSx Contract Interfaces
 * @dev Minimal, ABI-exact interfaces that match official Aragon OSx deployment
 */

// ============ Minimal ABI-Exact Interfaces ============

interface IDAOFactory {
    struct DAOSettings {
        address trustedForwarder;
        string daoURI;
        string subdomain;
        bytes metadata;
    }
    
    struct PluginSettings {
        PluginSetupRef pluginSetupRef;
        bytes data;
    }
    
    struct PluginSetupRef {
        VersionTag versionTag;
        address pluginSetupRepo;
    }
    
    struct VersionTag {
        uint8 release;
        uint16 build;
    }
    
    struct InstalledPlugin {
        address plugin;
        bytes32 helpersHash;
        bytes32 permissionsHash;
    }
    
    function createDao(
        DAOSettings calldata daoSettings,
        PluginSettings[] calldata pluginSettings
    ) external returns (
        address createdDao,
        InstalledPlugin[] memory installedPlugins
    );
}

interface IDAO {
    struct Action {
        address to;
        uint256 value;
        bytes data;
    }
    
    function execute(
        bytes32 callId,
        Action[] memory actions,
        uint256 allowFailureMap
    ) external returns (bytes[] memory execResults, uint256 failureMap);
    
    function hasPermission(
        address where,
        address who,
        bytes32 permissionId,
        bytes calldata data
    ) external view returns (bool);
}


// ============ Aragon OSx Network Configuration ============

library AragonOSxAddresses {
    // Official Sepolia Testnet Addresses from Aragon OSx artifacts
    address public constant SEPOLIA_DAO_FACTORY = 0xB815791c233807D39b7430127975244B36C19C8e; // CORRECTED: Real DAO Factory
    address public constant SEPOLIA_PLUGIN_SETUP_PROCESSOR = 0xC24188a73dc09aA7C721f96Ad8857B469C01dC9f; // Confirmed correct
    
    // Token Voting Plugin Repository (official from @aragon/token-voting-plugin-artifacts)
    address public constant SEPOLIA_TOKEN_VOTING_PLUGIN_REPO = 0x424F4cA6FA9c24C03f2396DF0E96057eD11CF7dF; // Official Token Voting plugin repo on Sepolia
    
    function getDaoFactory(uint256 chainId) internal pure returns (address) {
        if (chainId == 11155111) { // Sepolia
            return SEPOLIA_DAO_FACTORY;
        }
        revert("Unsupported network");
    }
    
    function getPluginSetupProcessor(uint256 chainId) internal pure returns (address) {
        if (chainId == 11155111) { // Sepolia
            return SEPOLIA_PLUGIN_SETUP_PROCESSOR;
        }
        revert("Unsupported network");
    }
    
    function getTokenVotingPluginRepo(uint256 chainId) internal pure returns (address) {
        if (chainId == 11155111) { // Sepolia
            require(SEPOLIA_TOKEN_VOTING_PLUGIN_REPO != address(0), "Token Voting Plugin Repo not configured");
            return SEPOLIA_TOKEN_VOTING_PLUGIN_REPO;
        }
        revert("Unsupported network");
    }
}