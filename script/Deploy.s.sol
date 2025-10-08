// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {CogniSignal} from "../src/CogniSignal.sol";

contract Deploy is Script {
    function run() external returns (CogniSignal) {
        address dao = vm.envAddress("DAO_ADDRESS");
        require(dao != address(0), "DAO_ADDRESS not set");
        require(dao != msg.sender, "DAO should not be deployer address");
        
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        
        CogniSignal signal = new CogniSignal(dao);
        
        vm.stopBroadcast();
        
        console2.log("=== Deployment Complete ===");
        console2.log("CogniSignal deployed to:", address(signal));
        console2.log("DAO address set to:", dao);
        console2.log("Chain ID:", block.chainid);
        
        return signal;
    }
}