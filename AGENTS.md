# CogniSignal Contract System

## Overview
Minimal on-chain governance events for GitHub operations via [cogni-git-admin](https://github.com/Cogni-DAO/cogni-git-admin).

## Status: Proof of Concept Working ✅
- **Contract:** `CogniSignal.sol` deployed and verified on Sepolia  
- **Address:** `0x8F26cF7b9ca6790385E255E8aB63acc35e7b9FB1`
- **Tests:** Unit + E2E tests passing (`forge test`)
- **Integration:** End-to-end integration with cogni-git-admin functioning
- **Deployment:** `make dao-setup` successfully deploys complete stack

## Current Limitations (POC Status)
- **Single Wallet Governance:** System uses single wallet execution for testing, not proper multi-signature DAO governance
- **Fragile Implementation:** Proof of concept implementation requires careful configuration
- **Production Readiness:** Requires proper permission setup and multi-signature governance before production use

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

## Development Setup

**Quick Start:** Deploy complete development stack (ERC20 → DAO → CogniSignal)
```bash
# Add to .env file:
WALLET_PRIVATE_KEY=0x...  # Funded Sepolia wallet
EVM_RPC_URL=https://eth-sepolia... # Sepolia RPC

# Deploy complete stack
make dao-setup

# Output includes environment variables for cogni-git-admin integration
# Copy the generated .env.{TOKEN_SYMBOL} file or console output to cogni-git-admin
```

**Integration:** The deployment generates environment variables compatible with cogni-git-admin:
- `E2E_ADMIN_PLUGIN_CONTRACT` - Admin plugin for Aragon OSx deployments
- `DAO_ADDRESS` - DAO contract address
- `GOVERNANCE_TOKEN` - ERC20 governance token address
- `SIGNAL_CONTRACT` - CogniSignal contract address

**Documentation:**
- `script/AGENTS.md` - Deployment scripts and setup guides
- `script/gov_providers/AGENTS.md` - Governance provider integration best practices

## Testing
```bash
forge test           # All tests (unit + e2e)
forge test --match-path test/unit/    # Unit tests only
forge test --match-path test/e2e/     # E2E tests only  
```

## Development Rules
- Keep minimal - events only, no state
- 100% test coverage for access control
- All events must be validated in tests
- E2E tests use real DAO address with forks
