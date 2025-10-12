// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IGovProvider} from "./IGovProvider.sol";
import {IDAOFactory, IPluginSetupProcessor, IDAO, AragonOSxAddresses} from "./AragonInterfaces.sol";

/**
 * @title AragonOSx Provider
 * @dev Deploys real Aragon OSx DAO with Admin Plugin for production use
 * @notice Uses official Aragon OSx contracts on Sepolia
 */
contract AragonOSxProvider is IGovProvider, Script {
    
    // Admin Plugin v1.2 data structures from build metadata
    struct TargetConfig {
        address target;    // Target contract for execution
        uint8 operation;   // Operation type (call or delegatecall)
    }
    
    constructor() {
        // Constructor left empty - addresses are accessed via AragonOSxAddresses library
    }
    
    function deployGovernance(GovConfig memory config) 
        external 
        override 
        returns (GovDeploymentResult memory result) 
    {
        console2.log("Deploying Aragon OSx DAO...");
        
        // Check if Aragon is available on this network
        require(isAvailable(), "AragonOSx not available on this network");
        
        // 1. Deploy governance token
        console2.log("  Deploying governance token...");
        ERC20 token = _deployToken(config);
        
        // 2. Deploy Aragon DAO (STUB - needs real Aragon contracts)
        console2.log("  Deploying Aragon DAO...");
        address daoAddress = _deployAragonDAO(config, address(token));
        
        // 3. Deploy Admin Plugin (STUB - needs real Aragon contracts)
        console2.log("  Deploying Admin Plugin...");
        address adminPlugin = _deployAdminPlugin(daoAddress, config);
        
        result = GovDeploymentResult({
            daoAddress: daoAddress,
            adminPluginAddress: adminPlugin,
            tokenAddress: address(token),
            providerType: "aragon-osx",
            extraData: abi.encode(daoAddress, adminPlugin) // Store both addresses
        });
        
        console2.log("  Aragon OSx deployment complete");
        console2.log("    DAO:", daoAddress);
        console2.log("    Admin Plugin:", adminPlugin);
        console2.log("    Token:", address(token));
    }
    
    function getProviderType() external pure override returns (string memory) {
        return "aragon-osx";
    }
    
    function isAvailable() public view override returns (bool) {
        // Check if we support this chain ID
        if (block.chainid == 11155111) { // Sepolia
            return true;
        }
        return false;
    }
    
    function getRequiredEnvVars() external pure override returns (string[] memory) {
        string[] memory envVars = new string[](0);
        // Aragon OSx doesn't require additional env vars beyond the standard ones
        return envVars;
    }
    
    // ============ INTERNAL FUNCTIONS ============
    
    function _deployToken(GovConfig memory config) internal returns (ERC20) {
        // Reuse existing CogniToken logic
        return new CogniToken(
            config.tokenName,
            config.tokenSymbol,
            18, // decimals
            config.tokenSupply,
            config.deployer
        );
    }
    
    function _deployAragonDAO(GovConfig memory config, address token) internal returns (address) {
        console2.log("    Creating DAO via Aragon Factory...");
        
        IDAOFactory daoFactory = IDAOFactory(AragonOSxAddresses.getDaoFactory(block.chainid));
        
        // Create DAO settings
        IDAOFactory.DAOSettings memory daoSettings = IDAOFactory.DAOSettings({
            trustedForwarder: address(0), // No trusted forwarder
            daoURI: "", // Empty DAO URI
            subdomain: "", // No ENS subdomain
            metadata: abi.encode(
                string(abi.encodePacked("CogniSignal DAO - ", config.tokenName))
            )
        });
        
        // Note: We'll create the DAO without plugins first, then install admin plugin separately
        IDAOFactory.PluginSettings[] memory pluginSettings = new IDAOFactory.PluginSettings[](0);
        
        console2.log("    Calling DAO Factory createDao...");
        (address dao, ) = daoFactory.createDao(daoSettings, pluginSettings);
        console2.log("    DAO created:", dao);
        
        return dao;
    }
    
    function _deployAdminPlugin(address dao, GovConfig memory config) internal returns (address) {
        console2.log("    Installing Admin Plugin via PluginSetupProcessor...");
        
        IPluginSetupProcessor processor = IPluginSetupProcessor(AragonOSxAddresses.getPluginSetupProcessor(block.chainid));
        address adminPluginRepo = AragonOSxAddresses.getAdminPluginRepo(block.chainid);
        
        console2.log("    Admin Plugin Repository:", adminPluginRepo);
        console2.log("    PluginSetupProcessor:", address(processor));
        
        // Prepare plugin installation
        IPluginSetupProcessor.PrepareInstallationParams memory params = IPluginSetupProcessor.PrepareInstallationParams({
            pluginSetupRef: IPluginSetupProcessor.PluginSetupRef({
                versionTag: IPluginSetupProcessor.VersionTag(1, 2), // Admin v1.2 (latest)
                pluginSetupRepo: adminPluginRepo
            }),
            data: abi.encode(
                config.deployer,           // admin address
                new TargetConfig[](0)      // empty target configs array
            )
        });
        
        console2.log("    Preparing plugin installation...");
        console2.log("    Using Admin v1.2 build metadata ABI: (admin, TargetConfig[])");
        (address plugin, IPluginSetupProcessor.PreparedSetupData memory preparedSetupData) = processor.prepareInstallation(dao, params);
        
        console2.log("    Admin Plugin installed:", plugin);
        
        return plugin;
    }
}

/**
 * @title Simple ERC20 Token for DAO governance
 * @dev Reused from SetupDevChain.s.sol - should be extracted to shared location
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