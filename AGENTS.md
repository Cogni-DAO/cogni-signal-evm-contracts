# CogniSignal Contract System

## Overview
Minimal on-chain governance events for GitHub operations via [cogni-git-admin](https://github.com/Cogni-DAO/cogni-git-admin).

## Status: Proof of Concept Working ✅
- **Contract:** `CogniSignal.sol` deployed and verified on Sepolia at `0x8F26cF7b9ca6790385E255E8aB63acc35e7b9FB1`
- **Integration:** End-to-end with cogni-git-admin functioning
- **Deployment:** `make dao-setup` deploys complete stack

## Current Limitations (POC)
- Single wallet execution for testing (not multi-signature governance)
- Requires careful configuration and setup
- Not production-ready without proper permission management

## Architecture
```
DAO → signal() → CogniAction event → Alchemy webhook → cogni-git-admin → GitHub API
```

## Contract Interface
```solidity
function signal(
    string calldata repo,     // "owner/repo"
    string calldata action,   // "PR_APPROVE"  
    string calldata target,   // "pull_request"
    uint256 pr,               // PR number
    bytes32 commit,           // Git commit hash
    bytes calldata extra      // ABI-encoded: (nonce, deadline, paramsJson)
) external onlyDAO;
```

## Events
```solidity
event CogniAction(
    address indexed dao,      // Fixed DAO address
    uint256 indexed chainId,  // Auto-generated
    string repo,              // Target repository
    string action,            // Action type
    string target,            // Action target
    uint256 pr,               // PR number
    bytes32 commit,           // Git commit
    bytes extra,              // Additional data
    address indexed executor  // Caller (same as DAO)
);
```

## Actions (MVP)
- `PR_APPROVE` - Approve pull requests

## Security
- `onlyDAO` modifier restricts access
- Event-only contract (no state changes)
- Verified on Etherscan for transparency

## Quick Start

```bash
# Setup environment
cp .env.TOKEN.example .env
# Edit .env with WALLET_PRIVATE_KEY and EVM_RPC_URL

# Deploy complete stack
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

