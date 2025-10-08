# cogni-signal-evm-contracts

Minimal EVM contracts that emit on-chain events to authorize GitHub admin actions via the cogni-admin app.

## Overview

The `CogniSignal` contract enables DAOs to execute governance decisions on GitHub repositories through deterministic on-chain events. Only the DAO can call `signal()`, which emits `CogniAction` events consumed by off-chain listeners.

## Core Contract

**`CogniSignal.sol`** - Emits `CogniAction` events with:
- `dao` (indexed) - DAO address that executed the signal
- `chainId` (indexed) - Chain where the signal was emitted  
- `repo` - Target GitHub repository
- `action` - Action type (e.g., "PR_APPROVE")
- `target` - Branch or target reference
- `pr` - Pull request number
- `commit` - Git commit hash (32 bytes)
- `extra` - ABI-encoded `(nonce, deadline, paramsJson)`
- `executor` (indexed) - Address that called the function

## Actions (v1)

- `PR_APPROVE` - Approve pull requests
- Future: `MERGE`, `LABEL`, `REVERT`

## Security

- Only the DAO address (set at deployment) can call `signal()`
- No state changes beyond event emission
- Off-chain verifiers handle nonce/deadline validation and replay protection

## Development

```bash
forge test        # Run tests
forge build       # Build contracts  
forge fmt         # Format code
```

See `AGENTS.md` for detailed technical specifications.

forge script script/Deploy.s.sol:Deploy --rpc-url testnet --broadcast --verify --etherscan-api-key <key optional>
