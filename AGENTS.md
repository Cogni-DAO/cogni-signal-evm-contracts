# CogniSignal Contract System

## Overview
Minimal on-chain governance events for GitHub operations via [cogni-git-admin](https://github.com/Cogni-DAO/cogni-git-admin).

## Status: Proof of Concept Working ✅
- **Contract:** `CogniSignal.sol` deployed and verified on Sepolia at `0x7115D79246D1aE2D4bF5a6D5fA626B426fE8F5cD`
- **Integration:** End-to-end with cogni-git-admin functioning
- **Deployment:** `make dao-setup` deploys complete stack with automatic verification

## Current Limitations (POC)
- Single wallet execution for testing (not multi-signature governance)
- Requires careful configuration and setup
- Not production-ready without proper permission management

## Architecture
```
DAO → signal() → CogniAction event → Alchemy webhook → cogni-git-admin → VCS Provider APIs
```

## Contract Interface
```solidity
function signal(
    string calldata vcs,       // "github" | "gitlab" | (future: "radicle" | "gerrit" | ... ) 
    string calldata repoUrl,   // Full VCS URL (github/gitlab/selfhosted)
    string calldata action,    // e.g. "merge", "grant", "revoke"
    string calldata target,    // e.g. "change", "collaborator", "branch"
    string calldata resource,  // e.g. "42" (PR number) or "alice" (username)
    bytes  calldata extra      // ABI-encoded: (nonce, deadline, paramsJson)
) external onlyDAO;
```

## Events
```solidity
event CogniAction(
    address indexed dao,       // Fixed DAO address
    uint256 indexed chainId,   // Auto-generated
    string  vcs,               // VCS provider type
    string  repoUrl,           // Full VCS URL
    string  action,            // Action type
    string  target,            // Action target  
    string  resource,          // Resource identifier
    bytes   extra,             // Additional data
    address indexed executor   // Caller (same as DAO)
);
```

## Actions (Multi-VCS)
- **Merge changes**: `action="merge"`, `target="change"`, `resource="{PR|MR|patch ID}"`
- **Grant access**: `action="grant"`, `target="collaborator"`, `resource="{username}"`
- **Revoke access**: `action="revoke"`, `target="collaborator"`, `resource="{username}"`

## VCS Provider Support
- **GitHub**: `repoUrl="https://github.com/owner/repo"`, `resource="{PR number}"`
- **GitLab**: `repoUrl="https://gitlab.com/owner/repo"`, `resource="{MR IID}"`
- **Self-hosted**: `repoUrl="https://git.company.com/owner/repo"`, `resource="{patch ID}"`

## Security
- `onlyDAO` modifier restricts access
- Event-only contract (no state changes)
- Verified on Etherscan for transparency

## Quick Start

```bash
# Setup environment
cp .env.TOKEN.example .env
# Edit .env with WALLET_PRIVATE_KEY, EVM_RPC_URL, and ETHERSCAN_API_KEY

# Deploy complete stack with automatic verification
make dao-setup

# Copy generated environment variables to cogni-git-admin
```

See `README.md` for detailed setup instructions.

## Testing
```bash
forge test           # All tests
forge test --match-path test/unit/    # Unit tests only
forge test --match-path test/e2e/     # E2E tests only  
```

