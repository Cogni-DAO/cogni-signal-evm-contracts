// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Action} from "@aragon/osx-commons-contracts/src/executors/IExecutor.sol";
import {PermissionManager} from "@aragon/osx/core/permission/PermissionManager.sol";
import {GovernanceERC20} from "token-voting-plugin/src/erc20/GovernanceERC20.sol";
import {TokenVoting} from "token-voting-plugin/src/TokenVoting.sol";
import {IMajorityVoting} from "token-voting-plugin/src/base/IMajorityVoting.sol";
import {FaucetMinter} from "../src/FaucetMinter.sol";

/**
 * @title Grant Mint Permission to Faucet Script
 * @dev Creates DAO proposal to grant MINT_PERMISSION_ID to faucet
 * 
 * Required Environment Variables:
 * - WALLET_PRIVATE_KEY: Private key with DAO proposal creation rights
 * - EVM_RPC_URL: RPC endpoint  
 * - DAO_ADDRESS: Address of the DAO
 * - GOVERNANCE_TOKEN: Address of the governance token
 * - FAUCET_ADDRESS: Address of the deployed faucet
 * - ARAGON_VOTING_PLUGIN_CONTRACT: Address of the TokenVoting plugin
 */
contract GrantMintToFaucet is Script {
    function run() external {
        // Load configuration
        uint256 deployerPrivateKey = uint256(vm.envBytes32("WALLET_PRIVATE_KEY"));
        address daoAddress = vm.envAddress("DAO_ADDRESS");
        address tokenAddress = vm.envAddress("GOVERNANCE_TOKEN");
        address faucetAddress = vm.envAddress("FAUCET_ADDRESS");
        address votingPluginAddress = vm.envAddress("ARAGON_VOTING_PLUGIN_CONTRACT");
        
        // Validate inputs
        require(daoAddress != address(0), "DAO address cannot be zero");
        require(tokenAddress != address(0), "Token address cannot be zero");
        require(faucetAddress != address(0), "Faucet address cannot be zero");
        require(votingPluginAddress != address(0), "Voting plugin address cannot be zero");
        
        console2.log("=== Creating Faucet Permission Proposal ===");
        console2.log("DAO Address:", daoAddress);
        console2.log("Token Address:", tokenAddress);
        console2.log("Faucet Address:", faucetAddress);
        console2.log("Voting Plugin:", votingPluginAddress);
        
        // Get contracts
        GovernanceERC20 token = GovernanceERC20(tokenAddress);
        FaucetMinter faucet = FaucetMinter(faucetAddress);
        TokenVoting voting = TokenVoting(votingPluginAddress);
        
        bytes32 mintPermissionId = token.MINT_PERMISSION_ID();
        bytes32 configPermissionId = faucet.CONFIG_PERMISSION_ID();
        bytes32 pausePermissionId = faucet.PAUSE_PERMISSION_ID();
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Build proposal actions using Action struct
        Action[] memory actions = new Action[](3);
        
        // Grant MINT_PERMISSION to faucet
        actions[0] = Action({
            to: daoAddress,
            value: 0,
            data: abi.encodeWithSelector(PermissionManager.grant.selector, tokenAddress, faucetAddress, mintPermissionId)
        });
        
        // Grant CONFIG_PERMISSION to DAO
        actions[1] = Action({
            to: daoAddress,
            value: 0,
            data: abi.encodeWithSelector(PermissionManager.grant.selector, faucetAddress, daoAddress, configPermissionId)
        });
        
        // Grant PAUSE_PERMISSION to DAO
        actions[2] = Action({
            to: daoAddress,
            value: 0,
            data: abi.encodeWithSelector(PermissionManager.grant.selector, faucetAddress, daoAddress, pausePermissionId)
        });
        
        string memory proposalMetadata = string(abi.encodePacked(
            "# Enable Token Faucet\\n\\n",
            "Enable the token faucet at `", vm.toString(faucetAddress), "` for new DAO members.\\n\\n",
            "**Actions:**\\n",
            "- Grant MINT_PERMISSION to faucet\\n",
            "- Grant CONFIG_PERMISSION to DAO\\n", 
            "- Grant PAUSE_PERMISSION to DAO"
        ));
        
        // Create proposal  
        console2.log("Creating proposal with", actions.length, "actions...");
        uint256 proposalId = voting.createProposal(
            abi.encode(proposalMetadata),
            actions,
            0, // allowFailureMap
            0, // startDate (immediate)
            0, // endDate (use plugin default)
            IMajorityVoting.VoteOption.None, // no auto vote
            true // tryEarlyExecution
        );
        
        console2.log("Proposal created successfully!");
        console2.log("Proposal ID:", proposalId);
        
        vm.stopBroadcast();
        
        console2.log("");
        console2.log("Next: DAO members vote on proposal", proposalId);
        console2.log("Faucet will be active after approval");
    }
}