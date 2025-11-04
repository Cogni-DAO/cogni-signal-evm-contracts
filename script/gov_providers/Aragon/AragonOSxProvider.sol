// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Import real types directly from official plugin sources  
import {Script, console2} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IGovProvider} from "../IGovProvider.sol";
import {DAOFactory} from "@aragon/osx/framework/dao/DAOFactory.sol";
import {IDAO} from "@aragon/osx-commons-contracts/src/dao/IDAO.sol";
import {IPluginSetup} from "@aragon/osx-commons-contracts/src/plugin/setup/IPluginSetup.sol";
import {PluginSetupRef} from "@aragon/osx/framework/plugin/setup/PluginSetupProcessorHelpers.sol";
import {PluginRepo} from "@aragon/osx/framework/plugin/repo/PluginRepo.sol";
import {MajorityVotingBase} from "token-voting-plugin/src/base/MajorityVotingBase.sol";
import {TokenVotingSetup} from "token-voting-plugin/src/TokenVotingSetup.sol";
import {TokenVoting} from "token-voting-plugin/src/TokenVoting.sol";
import {GovernanceERC20} from "token-voting-plugin/src/erc20/GovernanceERC20.sol";
import {NonTransferableVotes} from "../../../src/NonTransferableVotes.sol";
import {IPlugin} from "@aragon/osx-commons-contracts/src/plugin/IPlugin.sol";

/**
 * @title AragonOSx Provider
 * @dev Deploys real Aragon OSx DAO with Token Voting Plugin for co-op governance
 * @notice Uses official Aragon OSx contracts on Sepolia
 */
contract AragonOSxProvider is IGovProvider, Script {
    
    bytes32 constant EXECUTE = keccak256("EXECUTE_PERMISSION");
    
    constructor() {
        // Constructor left empty - addresses loaded from environment
    }
    
    function deployGovernance(GovConfig memory config) 
        external 
        override 
        returns (GovDeploymentResult memory result) 
    {
        console2.log("Deploying Aragon OSx DAO with Token Voting Plugin...");
        
        // Check if Aragon is available on this network
        require(isAvailable(), "AragonOSx not available on this network");
        
        // Decode Aragon addresses from provider-specific config (set by script from artifacts)
        (address daoFactory, address psp, address tokenVotingRepo) = 
            abi.decode(config.providerSpecificConfig, (address, address, address));
        
        // Validate external contract addresses have code
        require(daoFactory.code.length > 0, "no code: factory");
        require(psp.code.length > 0, "no code: psp");
        require(tokenVotingRepo.code.length > 0, "no code: token voting repo");
        
        // Verify PSP is wired correctly in factory
        address factoryPsp = address(DAOFactory(daoFactory).pluginSetupProcessor());
        require(factoryPsp == psp, "factory psp mismatch");
        
        
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
        string[] memory envVars = new string[](4);
        envVars[0] = "TOKEN_INITIAL_HOLDER";
        envVars[1] = "ARAGON_DAO_FACTORY";
        envVars[2] = "ARAGON_PSP";
        envVars[3] = "ARAGON_TOKEN_VOTING_REPO";
        return envVars;
    }
    
    // ============ INTERNAL FUNCTIONS ============
    
    function _deployDAOWithTokenVotingPlugin(
        GovConfig memory config,
        address daoFactory,
        address tokenVotingRepo,
        address /* psp */
    ) internal returns (address dao, address tokenVotingPlugin, address governanceToken) {
        DAOFactory.DAOSettings memory daoSettings = DAOFactory.DAOSettings({
            trustedForwarder: address(0),
            daoURI: "",
            subdomain: "",
            metadata: abi.encode(string(abi.encodePacked("CogniSignal DAO - ", config.tokenName)))
        });

        require(config.tokenInitialHolder != address(0), "zero initial holder");

        address[] memory receivers = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        receivers[0] = config.tokenInitialHolder;
        amounts[0] = 1e18;

        MajorityVotingBase.VotingSettings memory votingSettings;
        votingSettings.votingMode = MajorityVotingBase.VotingMode.EarlyExecution;
        votingSettings.supportThreshold = uint32(500_000);
        votingSettings.minParticipation = uint32(500_000);
        votingSettings.minDuration = uint64(3600);
        votingSettings.minProposerVotingPower = uint256(1e18);

        // Deploy custom non-transferable governance token
        NonTransferableVotes customToken = new NonTransferableVotes(
            config.tokenName,
            config.tokenSymbol
        );
        
        // Mint initial supply to holder
        customToken.mint(config.tokenInitialHolder, amounts[0]);

        TokenVotingSetup.TokenSettings memory tokenSettings = TokenVotingSetup.TokenSettings({
            addr: address(customToken),
            name: config.tokenName,
            symbol: config.tokenSymbol
        });

        // Avoid plugin-side mint to prevent double-mint
        address[] memory emptyReceivers;
        uint256[] memory emptyAmounts;
        GovernanceERC20.MintSettings memory mintSettings = GovernanceERC20.MintSettings({
            receivers: emptyReceivers,
            amounts: emptyAmounts,
            ensureDelegationOnMint: false
        });

        // Add the 4 missing parameters that TokenVotingSetup expects (7 total)
        IPlugin.TargetConfig memory targetConfig = IPlugin.TargetConfig({
            target: address(0), // Will be set to DAO address by plugin
            operation: IPlugin.Operation.Call
        });
        uint256 minApprovals = 0; // Default minimum approvals
        bytes memory pluginMetadata = ""; // Empty plugin metadata
        address[] memory excludedAccounts; // Empty excluded accounts array

        bytes memory tokenVotingData = abi.encode(
            votingSettings,     // 1. MajorityVotingBase.VotingSettings
            tokenSettings,      // 2. TokenSettings
            mintSettings,       // 3. GovernanceERC20.MintSettings
            targetConfig,       // 4. IPlugin.TargetConfig (was missing)
            minApprovals,       // 5. uint256 (was missing)
            pluginMetadata,     // 6. bytes (was missing)
            excludedAccounts    // 7. address[] (was missing)
        );

        DAOFactory.PluginSettings[] memory pluginSettings = new DAOFactory.PluginSettings[](1);
        pluginSettings[0] = DAOFactory.PluginSettings({
            pluginSetupRef: PluginSetupRef({
                versionTag: PluginRepo.Tag(1, 3), // v1.4 per TokenVotingSetup.sol
                pluginSetupRepo: PluginRepo(tokenVotingRepo)
            }),
            data: tokenVotingData
        });

        // Use Address.functionCall to bubble revert data verbatim
        bytes memory callData = abi.encodeWithSelector(
            DAOFactory.createDao.selector,
            daoSettings,
            pluginSettings
        );
        
        bytes memory returnData = Address.functionCall(daoFactory, callData);
        DAOFactory.InstalledPlugin[] memory installed;
        (dao, installed) = abi.decode(
            returnData,
            (address, DAOFactory.InstalledPlugin[])
        );

        require(installed.length > 0, "no plugins");
        tokenVotingPlugin = installed[0].plugin;
        require(tokenVotingPlugin != address(0) && tokenVotingPlugin.code.length > 0, "bad plugin");

        // Ask plugin for its governance token instead of placeholder
        governanceToken = address(TokenVoting(tokenVotingPlugin).getVotingToken());
        require(governanceToken != address(0) && governanceToken.code.length > 0, "bad token");
        
        // Hand control to the DAO
        customToken.transferOwnership(dao);
    }
    
    
}