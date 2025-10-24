// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice Generic VCS governance signaling: only the DAO may call signal()
contract CogniSignal {
    event CogniAction(
        address indexed dao,
        uint256 indexed chainId,
        string  vcs,       // "github" | "gitlab" | "radicle"
        string  repoUrl,   // full VCS URL (github/gitlab/selfhosted)
        string  action,    // e.g. "merge", "grant", "revoke"
        string  target,    // e.g. "change", "collaborator", "branch"
        string  resource,  // e.g. "42" (PR number) or "alice" (username)
        bytes   extra,     // abi.encode(nonce, deadline, paramsJson UTF-8)
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
        string calldata vcs,
        string calldata repoUrl,
        string calldata action,
        string calldata target,
        string calldata resource,
        bytes  calldata extra
    ) external onlyDAO {
        emit CogniAction(DAO, block.chainid, vcs, repoUrl, action, target, resource, extra, msg.sender);
    }
}
