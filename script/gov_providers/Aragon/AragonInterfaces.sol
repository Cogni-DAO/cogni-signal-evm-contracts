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

interface IPluginSetupProcessor {
    struct PrepareInstallationParams {
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
    
    struct PreparedSetupData {
        address[] helpers;
        bytes permissions;
    }
    
    function prepareInstallation(
        address dao,
        PrepareInstallationParams calldata params
    ) external returns (address plugin, PreparedSetupData memory preparedSetupData);
    
    function applyInstallation(
        address dao,
        PreparedSetupData calldata preparedSetupData
    ) external;
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

interface IAdminPlugin {
    function execute(
        IDAO.Action[] calldata actions,
        uint256 allowFailureMap
    ) external returns (bytes[] memory execResults, uint256 failureMap);
}

// ============ Aragon OSx Network Configuration ============
// Source: https://github.com/aragon/osx/releases v1.4.0

library AragonOSxAddresses {
    // Sepolia Testnet (11155111)
    address public constant SEPOLIA_DAO_FACTORY = 0xB815791c233807D39b7430127975244B36C19C8e;
    address public constant SEPOLIA_PLUGIN_SETUP_PROCESSOR = 0xC24188a73dc09aA7C721f96Ad8857B469C01dC9f;
    address public constant SEPOLIA_TOKEN_VOTING_REPO = 0x424F4cA6FA9c24C03f2396DF0E96057eD11CF7dF;
    address public constant SEPOLIA_ADMIN_PLUGIN_REPO = 0x152c9E28995E418870b85cbbc0AEE4e53020edb2;

    // Base Mainnet (8453) - v1.4.0
    address public constant BASE_MAINNET_DAO_FACTORY = 0xcc602EA573a42eBeC290f33F49D4A87177ebB8d2;
    address public constant BASE_MAINNET_PLUGIN_SETUP_PROCESSOR = 0x91a851E9Ed7F2c6d41b15F76e4a88f5A37067cC9;
    address public constant BASE_MAINNET_TOKEN_VOTING_REPO = 0x2532570DcFb749A7F976136CC05648ef2a0f60b0;
    address public constant BASE_MAINNET_ADMIN_PLUGIN_REPO = 0x212eF339C77B3390599caB4D46222D79fAabcb5c;

    // Base Sepolia Testnet (84532) - v1.4.0
    address public constant BASE_SEPOLIA_DAO_FACTORY = 0x016CBa9bd729C30b16849b2c52744447767E9dab;
    address public constant BASE_SEPOLIA_PLUGIN_SETUP_PROCESSOR = 0xd97D409Ca645b108468c26d8506f3a4Bf9D0BE81;
    address public constant BASE_SEPOLIA_TOKEN_VOTING_REPO = 0xdEbcF8779495a62156c6d1416628F60525984e9d;
    address public constant BASE_SEPOLIA_ADMIN_PLUGIN_REPO = 0x685FAE22Ad532ab642eBb85ae1517BC4F8db6804;

    function getDaoFactory(uint256 chainId) internal pure returns (address) {
        if (chainId == 11155111) return SEPOLIA_DAO_FACTORY;
        if (chainId == 8453) return BASE_MAINNET_DAO_FACTORY;
        if (chainId == 84532) return BASE_SEPOLIA_DAO_FACTORY;
        revert("Unsupported network: Aragon OSx not deployed");
    }

    function getPluginSetupProcessor(uint256 chainId) internal pure returns (address) {
        if (chainId == 11155111) return SEPOLIA_PLUGIN_SETUP_PROCESSOR;
        if (chainId == 8453) return BASE_MAINNET_PLUGIN_SETUP_PROCESSOR;
        if (chainId == 84532) return BASE_SEPOLIA_PLUGIN_SETUP_PROCESSOR;
        revert("Unsupported network: Aragon OSx not deployed");
    }

    function getTokenVotingRepo(uint256 chainId) internal pure returns (address) {
        if (chainId == 11155111) return SEPOLIA_TOKEN_VOTING_REPO;
        if (chainId == 8453) return BASE_MAINNET_TOKEN_VOTING_REPO;
        if (chainId == 84532) return BASE_SEPOLIA_TOKEN_VOTING_REPO;
        revert("Unsupported network: Aragon OSx not deployed");
    }

    function getAdminPluginRepo(uint256 chainId) internal pure returns (address) {
        if (chainId == 11155111) return SEPOLIA_ADMIN_PLUGIN_REPO;
        if (chainId == 8453) return BASE_MAINNET_ADMIN_PLUGIN_REPO;
        if (chainId == 84532) return BASE_SEPOLIA_ADMIN_PLUGIN_REPO;
        revert("Unsupported network: Aragon OSx not deployed");
    }
}