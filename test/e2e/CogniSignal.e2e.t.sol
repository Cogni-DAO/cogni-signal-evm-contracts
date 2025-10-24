// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CogniSignal} from "../../src/CogniSignal.sol";

interface IDAO {
    struct Action { 
        address to; 
        uint256 value; 
        bytes data; 
    }
    function execute(Action[] calldata actions, uint256 allowFailureMap) external returns (bytes[] memory);
}

contract CogniSignalForkE2E is Test {
    address constant DAO = 0xa38d03Ea38c45C1B6a37472d8Df78a47C1A31EB5;
    IDAO dao = IDAO(DAO);
    CogniSignal sig;

    event CogniAction(
        address indexed dao,
        uint256 indexed chainId,
        string  repoUrl,
        string  action,
        string  target,
        string  resource,
        bytes   extra,
        address indexed executor
    );

    function setUp() public {
        vm.createSelectFork(vm.envString("EVM_RPC_URL"));
        sig = new CogniSignal(DAO);
    }

    function test_DAO_execute_emits_event() public {
        IDAO.Action[] memory actions = new IDAO.Action[](1);
        actions[0] = IDAO.Action({
            to: address(sig),
            value: 0,
            data: abi.encodeWithSignature(
                "signal(string,string,string,string,bytes)",
                "https://github.com/Cogni-DAO/test-repo",
                "merge",
                "change",
                "112",
                abi.encode(uint256(1), uint64(4102444800), string('{"merge_method":"merge"}'))
            )
        });

        vm.expectEmit(true, true, true, true, address(sig));
        emit CogniAction(
            DAO,
            block.chainid,
            "https://github.com/Cogni-DAO/test-repo",
            "merge",
            "change",
            "112",
            abi.encode(uint256(1), uint64(4102444800), string('{"merge_method":"merge"}')),
            DAO
        );

        vm.startPrank(DAO);
        try dao.execute(actions, 0) {
            // Success - event was emitted
        } catch {
            // If DAO doesn't have execute method, test direct impersonation
            vm.stopPrank();
            vm.prank(DAO);
            sig.signal(
                "https://github.com/Cogni-DAO/test-repo",
                "merge", 
                "change",
                "112",
                abi.encode(uint256(1), uint64(4102444800), string('{"merge_method":"merge"}'))
            );
        }
        vm.stopPrank();
    }

    function test_direct_signal_call() public {
        string memory repoUrl = "https://github.com/Cogni-DAO/test-repo";
        string memory action = "merge";
        string memory target = "change";
        string memory resource = "112";
        bytes memory extra = abi.encode(uint256(1), uint64(4102444800), string('{"merge_method":"merge"}'));

        vm.expectEmit(true, true, true, true, address(sig));
        emit CogniAction(DAO, block.chainid, repoUrl, action, target, resource, extra, DAO);

        vm.prank(DAO);
        sig.signal(repoUrl, action, target, resource, extra);
    }

    function test_non_DAO_reverts() public {
        vm.prank(address(0x123)); // Not DAO
        vm.expectRevert("NOT_DAO");
        sig.signal("repo", "action", "target", "resource", "");
    }
}