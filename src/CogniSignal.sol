// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice Minimal: only the DAO may call signal()
contract CogniSignal {
    event CogniAction(
        address indexed dao,
        uint256 indexed chainId,
        string repo,
        string action,
        string target,
        uint256 pr,
        bytes32 commit, // 32-byte full SHA ok
        bytes extra,    // abi.encode(nonce, deadline, paramsJson)
        address indexed executor
    );

    address public immutable DAO;

    constructor(address dao) {
        DAO = dao;
    }

    modifier onlyDAO() {
        require(msg.sender == DAO, "NOT_DAO");
        _;
    }

    function signal(
        string calldata repo,
        string calldata action,
        string calldata target,
        uint256 pr,
        bytes32 commit,
        bytes calldata extra
    ) external onlyDAO {
        uint256 id; assembly { id := chainid() }
        emit CogniAction(DAO, id, repo, action, target, pr, commit, extra, msg.sender);
    }
}
