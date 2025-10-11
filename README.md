# CogniSignal EVM Contracts

Minimal on-chain governance signals for GitHub operations via [cogni-git-admin](https://github.com/Cogni-DAO/cogni-git-admin).

## Quick Start

```bash
forge test        # Run all tests
forge build       # Build contracts
```

## Contract

**`CogniSignal.sol`** - DAO-only contract that emits `CogniAction` events for GitHub operations.

- **Sepolia:** `0x8F26cF7b9ca6790385E255E8aB63acc35e7b9FB1` ✅ [Verified](https://sepolia.etherscan.io/address/0x8f26cf7b9ca6790385e255e8ab63acc35e7b9fb1)
- **DAO:** `0xa38d03Ea38c45C1B6a37472d8Df78a47C1A31EB5`

## Actions (MVP)

- `PR_APPROVE` - Approve pull requests

## Architecture

1. DAO calls `signal(repo, action, target, pr, commit, extra)`  
2. Contract emits `CogniAction` event
3. [cogni-git-admin](https://github.com/Cogni-DAO/cogni-git-admin) processes via Alchemy webhooks
4. GitHub action executed

## Deployment

```bash
# Set environment variables
export DAO_ADDRESS=0xa38d03Ea38c45C1B6a37472d8Df78a47C1A31EB5
export RPC_URL=<sepolia_rpc>
export ETHERSCAN_API_KEY=<key>

# Deploy and verify
forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --broadcast --verify
```

See `AGENTS.md` for technical details and `COGNI-GIT-ADMIN-INTEGRATION.md` for integration guide.
