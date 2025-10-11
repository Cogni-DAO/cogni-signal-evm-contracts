# CogniSignal Contract Integration

On-chain governance signals for GitHub operations via [cogni-git-admin](https://github.com/Cogni-DAO/cogni-git-admin/blob/main/AGENTS.md).

## Contract Details
- **Address:** `0x8F26cF7b9ca6790385E255E8aB63acc35e7b9FB1`
- **Network:** Sepolia (Chain ID: 11155111) 
- **DAO:** `0xa38d03Ea38c45C1B6a37472d8Df78a47C1A31EB5`
- **Status:** ✅ [Verified on Etherscan](https://sepolia.etherscan.io/address/0x8f26cf7b9ca6790385e255e8ab63acc35e7b9fb1)

## CogniAction Event

```solidity
event CogniAction(
    address indexed dao,      // DAO address (0xa38d03Ea38c45C1B6a37472d8Df78a47C1A31EB5)
    uint256 indexed chainId,  // Chain ID (11155111 for Sepolia) 
    string repo,              // GitHub repo (e.g. "owner/repo")
    string action,            // Action type (e.g. "PR_APPROVE")
    string target,            // Target (e.g. "pull_request")
    uint256 pr,               // Pull request number
    bytes32 commit,           // Git commit hash
    bytes extra,              // ABI-encoded: (nonce, deadline, paramsJson)
    address indexed executor  // Caller address (same as dao)
);
```

**Topic Hash:** `0xfd9a8ea95d56c7bd709823c6589c50386a2e5833892ef0e93c7bf63fee30bde1`

## Implementation

The [cogni-git-admin](https://github.com/Cogni-DAO/cogni-git-admin) processes these events via:

1. **Webhook Reception** - Alchemy webhooks to `/api/v1/webhooks/onchain/cogni-signal`
2. **Transaction Parsing** - Extract CogniAction events from transaction logs
3. **Validation** - Verify chain ID and DAO address match expected values
4. **GitHub Execution** - Convert governance signals to GitHub operations

### Environment Variables
```bash
COGNI_CHAIN_ID=11155111                                        # Sepolia
COGNI_SIGNAL_CONTRACT=0x8F26cF7b9ca6790385E255E8aB63acc35e7b9FB1
COGNI_ALLOWED_DAO=0xa38d03ea38c45c1b6a37472d8df78a47c1a31eb5  # Lowercase
```

### Example Decoded Event
```typescript
{
  dao: "0xa38d03Ea38c45C1B6a37472d8Df78a47C1A31EB5",
  chainId: 11155111n,
  repo: "owner/repo",
  action: "PR_APPROVE", 
  target: "pull_request",
  pr: 123,
  commit: "0x...",
  extra: "0x...", // ABI-encoded: (nonce, deadline, paramsJson)
  executor: "0xa38d03Ea38c45C1B6a37472d8Df78a47C1A31EB5"
}
```

## Webhook Setup

Configure Alchemy webhooks to monitor the contract:

```json
{
  "webhook_type": "ADDRESS_ACTIVITY", 
  "addresses": ["0x8F26cF7b9ca6790385E255E8aB63acc35e7b9FB1"],
  "network": "SEPOLIA"
}
```

Point webhook URL to your cogni-git-admin instance:
```
https://your-domain.com/api/v1/webhooks/onchain/cogni-signal
```

## Security
- Only DAO address can call `signal()` (enforced by `onlyDAO` modifier)
- Contract verified on Etherscan for transparency  
- cogni-git-admin validates chain ID and DAO address on every event