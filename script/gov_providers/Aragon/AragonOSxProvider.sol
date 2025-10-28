// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IGovProvider} from "../IGovProvider.sol";
import {IDAOFactory, IDAO, AragonOSxAddresses} from "./AragonInterfaces.sol";
// Import real types directly from official plugin sources  
import {MajorityVotingBase} from "token-voting-plugin/src/base/MajorityVotingBase.sol";
import {TokenVotingSetup} from "token-voting-plugin/src/TokenVotingSetup.sol";
import {GovernanceERC20} from "token-voting-plugin/src/erc20/GovernanceERC20.sol";

/**
 * @title AragonOSx Provider
 * @dev Deploys real Aragon OSx DAO with Token Voting Plugin for co-op governance
 * @notice Uses official Aragon OSx contracts on Sepolia
 */
contract AragonOSxProvider is IGovProvider, Script {
    
    bytes32 constant EXECUTE = keccak256("EXECUTE_PERMISSION");
    
    constructor() {
        // Constructor left empty - addresses are accessed via AragonOSxAddresses library
    }
    
    function deployGovernance(GovConfig memory config) 
        external 
        override 
        returns (GovDeploymentResult memory result) 
    {
        console2.log("Deploying Aragon OSx DAO with Token Voting Plugin...");
        
        // Check if Aragon is available on this network
        require(isAvailable(), "AragonOSx not available on this network");
        
        // Validate external contract addresses have code
        address daoFactory = AragonOSxAddresses.getDaoFactory(block.chainid);
        address psp = AragonOSxAddresses.getPluginSetupProcessor(block.chainid);
        address tokenVotingRepo = AragonOSxAddresses.getTokenVotingPluginRepo(block.chainid);
        
        require(daoFactory.code.length > 0, "no code: factory");
        require(psp.code.length > 0, "no code: psp");
        require(tokenVotingRepo.code.length > 0, "no code: token voting repo");
        
        
        // Note: Token will be created by the TokenVoting plugin, not deployed here
        
        // 2. Deploy DAO with Token Voting Plugin via DAOFactory
        console2.log("  Deploying DAO with Token Voting Plugin via Factory...");
        (address daoAddress, address tokenVotingPlugin, address govToken) = _deployDAOWithTokenVotingPlugin(config, daoFactory, tokenVotingRepo, psp);
        
        // 3. Validate deployment
        require(daoAddress.code.length > 0, "no code: dao");
        require(tokenVotingPlugin.code.length > 0, "no code: plugin");
        require(govToken.code.length > 0, "no code: governance token");
        
        result = GovDeploymentResult({
            daoAddress: daoAddress,
            votingPluginAddress: tokenVotingPlugin,
            tokenAddress: govToken,
            providerType: "aragon-osx",
            extraData: abi.encode(daoAddress, tokenVotingPlugin, govToken)
        });
        
        console2.log("  Aragon OSx deployment complete");
        console2.log("    DAO:", daoAddress);
        console2.log("    Token Voting Plugin:", tokenVotingPlugin);
        console2.log("    Governance Token:", govToken);
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
        string[] memory envVars = new string[](1);
        envVars[0] = "TOKEN_INITIAL_HOLDER";
        return envVars;
    }
    
    // ============ INTERNAL FUNCTIONS ============
    
    function _deployDAOWithTokenVotingPlugin(
        GovConfig memory config, 
        address daoFactory, 
        address tokenVotingRepo,
        address /* psp */
    ) internal returns (address dao, address tokenVotingPlugin, address governanceToken) {
        
        // Create DAO settings
        IDAOFactory.DAOSettings memory daoSettings = IDAOFactory.DAOSettings({
            trustedForwarder: address(0), // No trusted forwarder
            daoURI: "", // Empty DAO URI
            subdomain: "", // No ENS subdomain
            metadata: abi.encode(
                string(abi.encodePacked("CogniSignal DAO - ", config.tokenName))
            )
        });
        
        address initialHolder = abi.decode(config.providerSpecificConfig, (address));
        
        // Create mint recipients with proper token decimals (18 decimals = 1e18)
        address[] memory receivers = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        receivers[0] = initialHolder;
        amounts[0] = 1e18; // Use 18-decimal token amount instead of 1
        
        // Create VotingSettings with absolutely explicit typing to prevent truncation
        MajorityVotingBase.VotingSettings memory votingSettings;
        votingSettings.votingMode = MajorityVotingBase.VotingMode.Standard;  // 0
        votingSettings.supportThreshold = uint32(500000);        // 500000 
        votingSettings.minParticipation = uint32(500000);        // 500000
        votingSettings.minDuration = uint64(3600);               // 3600 (0xe10 hex)
        votingSettings.minProposerVotingPower = uint256(1e18);   // 1e18
        
        // Debug log to verify minDuration value
        console2.log("  DEBUG: VotingSettings.minDuration =", votingSettings.minDuration);
        
        // Create TokenSettings struct (plugin will deploy GovernanceERC20)
        TokenVotingSetup.TokenSettings memory tokenSettings = TokenVotingSetup.TokenSettings({
            addr: address(0),                         // address(0) = deploy new GovernanceERC20
            name: config.tokenName,                   // Token name
            symbol: config.tokenSymbol               // Token symbol
        });
        
        // Create MintSettings struct with proper decimals (3 fields - GovernanceERC20.MintSettings)
        GovernanceERC20.MintSettings memory mintSettings = GovernanceERC20.MintSettings({
            receivers: receivers,                     // Recipients of initial tokens
            amounts: amounts,                         // Token amounts (1e18 for 18 decimals)
            ensureDelegationOnMint: true              // Ensure delegation on mint for voting
        });
        
        // Encode the three structs as parameters for TokenVotingSetup::prepareInstallation
        bytes memory tokenVotingData = abi.encode(
            votingSettings,
            tokenSettings,
            mintSettings
        );
        
        // Debug: Log the encoded data to see what's actually being sent
        console2.log("  DEBUG: Encoded data length:", tokenVotingData.length);
        console2.logBytes(tokenVotingData);
        
        IDAOFactory.PluginSettings[] memory pluginSettings = new IDAOFactory.PluginSettings[](1);
        pluginSettings[0] = IDAOFactory.PluginSettings({
            pluginSetupRef: IDAOFactory.PluginSetupRef({
                versionTag: IDAOFactory.VersionTag(1, 3), // Token Voting v1.3
                pluginSetupRepo: tokenVotingRepo
            }),
            data: tokenVotingData
        });
        
        // Create DAO with Token Voting Plugin
        IDAOFactory.InstalledPlugin[] memory installedPlugins;
        (dao, installedPlugins) = IDAOFactory(daoFactory).createDao(daoSettings, pluginSettings);
        
        // Get plugin from return value
        require(installedPlugins.length > 0, "no plugins installed");
        
        // Use installedPlugins[0].plugin as per reviewer guidance
        tokenVotingPlugin = installedPlugins[0].plugin;
        require(tokenVotingPlugin != address(0) && tokenVotingPlugin.code.length > 0, "token voting plugin not found");
        
        // The governance token address should be available from plugin helpers
        // For now, we'll extract it from the plugin's token() method or similar
        // TODO: Get actual governance token address from plugin setup  
        governanceToken = tokenVotingPlugin; // Placeholder - needs proper extraction
        
    }
    
    
}