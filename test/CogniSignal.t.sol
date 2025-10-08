// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {CogniSignal} from "../src/CogniSignal.sol";

contract CogniSignalTest is Test {
    CogniSignal public signal;
    address public constant DAO = address(0x123);
    address public constant NOT_DAO = address(0x456);

    event CogniAction(
        address indexed dao,
        uint256 indexed chainId,
        string repo,
        string action,
        string target,
        uint256 pr,
        bytes32 commit,
        bytes extra,
        address indexed executor
    );

    function setUp() public {
        signal = new CogniSignal(DAO);
    }

    function test_Constructor() public view {
        assertEq(signal.DAO(), DAO);
    }

    function test_Signal_Success() public {
        string memory repo = "Cogni-DAO/test-repo";
        string memory action = "PR_APPROVE";
        string memory target = "main";
        uint256 pr = 123;
        bytes32 commit = keccak256("commit123");
        bytes memory extra = abi.encode(1, block.timestamp + 1 hours, '{"approved": true}');

        vm.prank(DAO);
        
        vm.expectEmit(true, true, true, true);
        emit CogniAction(DAO, block.chainid, repo, action, target, pr, commit, extra, DAO);
        
        signal.signal(repo, action, target, pr, commit, extra);
    }

    function test_Signal_RevertWhen_NotDAO() public {
        vm.prank(NOT_DAO);
        vm.expectRevert("NOT_DAO");
        signal.signal("repo", "action", "target", 0, bytes32(0), "");
    }

    function test_Signal_EventFields() public {
        string memory repo = "Cogni-DAO/cogni-signal-evm-contracts";
        string memory action = "PR_APPROVE";
        string memory target = "feature/new-feature";
        uint256 pr = 42;
        bytes32 commit = 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef;
        uint256 nonce = 1;
        uint256 deadline = block.timestamp + 1 hours;
        string memory paramsJson = '{"reviewers": ["alice", "bob"], "required": 2}';
        bytes memory extra = abi.encode(nonce, deadline, paramsJson);

        vm.prank(DAO);
        
        vm.recordLogs();
        signal.signal(repo, action, target, pr, commit, extra);
        
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 1);
        assertEq(logs[0].topics.length, 4);
        assertEq(logs[0].topics[0], keccak256("CogniAction(address,uint256,string,string,string,uint256,bytes32,bytes,address)"));
        assertEq(logs[0].topics[1], bytes32(uint256(uint160(DAO))));
        assertEq(logs[0].topics[2], bytes32(block.chainid));
        assertEq(logs[0].topics[3], bytes32(uint256(uint160(DAO))));
    }

    function test_Signal_MultipleActions() public {
        vm.startPrank(DAO);
        
        signal.signal("repo1", "PR_APPROVE", "main", 1, bytes32(uint256(1)), "");
        signal.signal("repo2", "PR_APPROVE", "dev", 2, bytes32(uint256(2)), "");
        
        vm.stopPrank();
    }

    function testFuzz_Signal_Parameters(
        string memory repo,
        string memory action,
        string memory target,
        uint256 pr,
        bytes32 commit,
        bytes memory extra
    ) public {
        vm.prank(DAO);
        
        vm.expectEmit(true, true, true, true);
        emit CogniAction(DAO, block.chainid, repo, action, target, pr, commit, extra, DAO);
        
        signal.signal(repo, action, target, pr, commit, extra);
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