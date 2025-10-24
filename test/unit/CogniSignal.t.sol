// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {CogniSignal} from "../../src/CogniSignal.sol";

contract CogniSignalTest is Test {
    CogniSignal public signal;
    address public constant DAO = address(0x123);
    address public constant NOT_DAO = address(0x456);

    event CogniAction(
        address indexed dao,
        uint256 indexed chainId,
        string  vcs,
        string  repoUrl,
        string  action,
        string  target,
        string  resource,
        bytes   extra,
        address indexed executor
    );

    function setUp() public {
        signal = new CogniSignal(DAO);
    }

    function test_Constructor() public view {
        assertEq(signal.DAO(), DAO);
    }

    function test_Signal_Success() public {
        string memory vcs = "github";
        string memory repoUrl = "https://github.com/Cogni-DAO/test-repo";
        string memory action = "merge";
        string memory target = "change";
        string memory resource = "42";
        bytes memory extra = abi.encode(1, block.timestamp + 1 hours, '{"merge_method":"merge"}');

        vm.prank(DAO);
        
        vm.expectEmit(true, true, true, true);
        emit CogniAction(DAO, block.chainid, vcs, repoUrl, action, target, resource, extra, DAO);
        
        signal.signal(vcs, repoUrl, action, target, resource, extra);
    }

    function test_Signal_RevertWhen_NotDAO() public {
        vm.prank(NOT_DAO);
        vm.expectRevert("NOT_DAO");
        signal.signal("vcs", "repo", "action", "target", "resource", "");
    }

    function test_Signal_EventFields() public {
        string memory vcs = "gitlab";
        string memory repoUrl = "https://gitlab.com/Cogni-DAO/test-repo";
        string memory action = "grant";
        string memory target = "collaborator";
        string memory resource = "alice";
        uint256 nonce = 1;
        uint256 deadline = block.timestamp + 1 hours;
        string memory paramsJson = '{"permission": "admin"}';
        bytes memory extra = abi.encode(nonce, deadline, paramsJson);

        vm.prank(DAO);
        
        vm.recordLogs();
        signal.signal(vcs, repoUrl, action, target, resource, extra);
        
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 1);
        assertEq(logs[0].topics.length, 4);
        assertEq(logs[0].topics[0], keccak256("CogniAction(address,uint256,string,string,string,string,string,bytes,address)"));
        assertEq(logs[0].topics[1], bytes32(uint256(uint160(DAO))));
        assertEq(logs[0].topics[2], bytes32(block.chainid));
        assertEq(logs[0].topics[3], bytes32(uint256(uint160(DAO))));
    }

    function test_Signal_MultipleActions() public {
        vm.startPrank(DAO);
        
        signal.signal("github", "https://github.com/Cogni-DAO/repo1", "merge", "change", "1", "");
        signal.signal("gitlab", "https://gitlab.com/Cogni-DAO/repo2", "grant", "collaborator", "alice", "");
        
        vm.stopPrank();
    }

    function testFuzz_Signal_Parameters(
        string memory vcs,
        string memory repoUrl,
        string memory action,
        string memory target,
        string memory resource,
        bytes memory extra
    ) public {
        vm.prank(DAO);
        
        vm.expectEmit(true, true, true, true);
        emit CogniAction(DAO, block.chainid, vcs, repoUrl, action, target, resource, extra, DAO);
        
        signal.signal(vcs, repoUrl, action, target, resource, extra);
    }

    function test_ExtraData_Encoding() public view {
        uint256 nonce = 123;
        uint256 deadline = block.timestamp + 3600;
        string memory paramsJson = '{"action": "approve", "required_reviewers": 2}';
        
        bytes memory encoded = abi.encode(nonce, deadline, paramsJson);
        (uint256 decodedNonce, uint256 decodedDeadline, string memory decodedJson) = 
            abi.decode(encoded, (uint256, uint256, string));
        
        assertEq(decodedNonce, nonce);
        assertEq(decodedDeadline, deadline);
        assertEq(decodedJson, paramsJson);
    }
}