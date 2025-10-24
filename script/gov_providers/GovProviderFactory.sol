// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {IGovProvider} from "./IGovProvider.sol";
import {AragonOSxProvider} from "./AragonOSxProvider.sol";
import {SimpleDaoProvider} from "./SimpleDaoProvider.sol";

/**
 * @title Governance Provider Factory
 * @dev Factory for creating governance providers with auto-fallback logic
 */
library GovProviderFactory {
    
    enum ProviderType {
        ARAGON,     // Aragon OSx (default)
        SIMPLE      // SimpleDAO (development)
    }
    
    /**
     * @dev Create governance provider based on type and availability
     * @param providerType Desired provider type
     * @return provider Governance provider instance
     */
    function createProvider(ProviderType providerType) 
        internal 
        returns (IGovProvider provider) 
    {
        console2.log("Selecting governance provider...");
        
        if (providerType == ProviderType.ARAGON) {
            AragonOSxProvider aragonProvider = new AragonOSxProvider();
            require(aragonProvider.isAvailable(), "Aragon OSx not available on this network");
            console2.log("  Selected: Aragon OSx (forced)");
            return aragonProvider;
        } else {
            console2.log("  Selected: SimpleDAO (forced)");
            return new SimpleDaoProvider();
        }
    }
    
    /**
     * @dev Parse provider type from environment variable
     * @param envValue Environment variable value
     * @return providerType Parsed provider type
     */
    function parseProviderType(string memory envValue) 
        internal 
        pure 
        returns (ProviderType) 
    {
        bytes32 valueHash = keccak256(abi.encodePacked(envValue));
        
        if (valueHash == keccak256("simple") || valueHash == keccak256("simple-dao")) {
            return ProviderType.SIMPLE;
        } else if (valueHash == keccak256("aragon") || valueHash == keccak256("aragon-osx")) {
            return ProviderType.ARAGON;
        } else {
            return ProviderType.ARAGON; // Default to Aragon
        }
    }
    
    /**
     * @dev Get provider type name for logging
     */
    function getProviderTypeName(ProviderType providerType) 
        internal 
        pure 
        returns (string memory) 
    {
        if (providerType == ProviderType.SIMPLE) {
            return "simple";
        } else {
            return "aragon-osx";
        }
    }
}