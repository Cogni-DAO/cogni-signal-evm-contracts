// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IGovProvider} from "./IGovProvider.sol";
import {IDAOFactory, IPluginSetupProcessor, IDAO, IAdminPlugin, AragonOSxAddresses} from "./AragonInterfaces.sol";

/**
 * @title AragonOSx Provider
 * @dev Deploys real Aragon OSx DAO with Admin Plugin for production use
 * @notice Uses official Aragon OSx contracts on Sepolia
 */
contract AragonOSxProvider is IGovProvider, Script {
    
    bytes32 constant EXECUTE = keccak256("EXECUTE_PERMISSION");
    
    // Admin Plugin v1.2 TargetConfig struct from build metadata
    struct TargetConfig {
        address target;    // Target contract for execution
        uint8 operation;   // Operation type (0=call, 1=delegatecall)
    }
    
    constructor() {
        // Constructor left empty - addresses are accessed via AragonOSxAddresses library
    }
    
    function deployGovernance(GovConfig memory config) 
        external 
        override 
        returns (GovDeploymentResult memory result) 
    {
        console2.log("Deploying Aragon OSx DAO with Admin Plugin...");
        
        // Check if Aragon is available on this network
        require(isAvailable(), "AragonOSx not available on this network");
        
        // Validate external contract addresses have code
        address daoFactory = AragonOSxAddresses.getDaoFactory(block.chainid);
        address psp = AragonOSxAddresses.getPluginSetupProcessor(block.chainid);
        address adminRepo = AragonOSxAddresses.getAdminPluginRepo(block.chainid);
        
        require(daoFactory.code.length > 0, "no code: factory");
        require(psp.code.length > 0, "no code: psp");
        require(adminRepo.code.length > 0, "no code: admin repo");
        
        console2.log("  External contracts validated");
        
        // 1. Deploy governance token
        console2.log("  Deploying governance token...");
        ERC20 token = _deployToken(config);
        
        // 2. Deploy DAO with Admin Plugin via DAOFactory
        console2.log("  Deploying DAO with Admin Plugin via Factory...");
        (address daoAddress, address adminPlugin) = _deployDAOWithAdminPlugin(config, daoFactory, adminRepo, psp);
        
        // 3. Validate deployment
        require(daoAddress.code.length > 0, "no code: dao");
        require(adminPlugin.code.length > 0, "no code: plugin");
        
        // 4. Validate AdminPlugin deployment
        console2.log("  Validating AdminPlugin deployment...");
        
        console2.log("  AdminPlugin deployment complete");
        
        result = GovDeploymentResult({
            daoAddress: daoAddress,
            adminPluginAddress: adminPlugin,
            tokenAddress: address(token),
            providerType: "aragon-osx",
            extraData: abi.encode(daoAddress, adminPlugin)
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
    
    function _deployDAOWithAdminPlugin(
        GovConfig memory config, 
        address daoFactory, 
        address adminRepo,
        address /* psp */
    ) internal returns (address dao, address adminPlugin) {
        console2.log("    Creating DAO with Admin Plugin via Factory...");
        
        // Create DAO settings
        IDAOFactory.DAOSettings memory daoSettings = IDAOFactory.DAOSettings({
            trustedForwarder: address(0), // No trusted forwarder
            daoURI: "", // Empty DAO URI
            subdomain: "", // No ENS subdomain
            metadata: abi.encode(
                string(abi.encodePacked("CogniSignal DAO - ", config.tokenName))
            )
        });
        
        // Prepare Admin Plugin settings with correct data encoding from build metadata
        // Admin v1.2 expects: (address admin, tuple config) per JSON
        bytes memory adminPluginData = abi.encode(config.deployer, TargetConfig(address(0), 0));
        
        IDAOFactory.PluginSettings[] memory pluginSettings = new IDAOFactory.PluginSettings[](1);
        pluginSettings[0] = IDAOFactory.PluginSettings({
            pluginSetupRef: IDAOFactory.PluginSetupRef({
                versionTag: IDAOFactory.VersionTag(1, 2), // Admin v1.2
                pluginSetupRepo: adminRepo
            }),
            data: adminPluginData
        });
        
        console2.log("    Data encoded from build metadata: (admin, tuple)");
        console2.log("    Admin address:", config.deployer);
        console2.log("    TargetConfig: target=0x0, operation=0");
        
        // Create DAO with Admin Plugin and get plugin from return value
        IDAOFactory.InstalledPlugin[] memory installedPlugins;
        (dao, installedPlugins) = IDAOFactory(daoFactory).createDao(daoSettings, pluginSettings);
        
        console2.log("    DAO created:", dao);
        
        // Get admin plugin from return value
        require(installedPlugins.length > 0, "no plugins installed");
        
        // The actual plugin address is in the helpersHash field due to Aragon's return value packing
        adminPlugin = address(uint160(uint256(installedPlugins[0].helpersHash)));
        require(adminPlugin != address(0) && adminPlugin.code.length > 0, "plugin not found");
        
        console2.log("    Admin Plugin from return value:", adminPlugin);
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