# Faucet Integration Guide

## Deep Link Template

```
/join?chainId=11155111&faucet=0x...&token=0x...&amount=1&decimals=18
```

## Required Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `chainId` | number | Network chain ID | `11155111` (Sepolia) |
| `faucet` | address | FaucetMinter contract address | `0x1234...abcd` |
| `token` | address | GovernanceERC20 token address | `0x5678...efgh` |
| `amount` | number | Tokens per claim (display value) | `1` |
| `decimals` | number | Token decimals for display | `18` |

## Contract Call

```typescript
import { writeContract } from 'viem'"

// Simple claim call - no parameters needed
const hash = await writeContract({
  address: faucet,        // From deep link
  abi: faucetABI,
  functionName: 'claim',
  // No args - msg.sender gets tokens automatically
})
```

## Contract ABI (Minimal)

```json
[
  {
    "type": "function",
    "name": "claim",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function", 
    "name": "hasClaimed",
    "inputs": [{"type": "address", "name": "claimer"}],
    "outputs": [{"type": "bool"}],
    "stateMutability": "view"
  },
  {
    "type": "event",
    "name": "Claimed",
    "inputs": [
      {"type": "address", "name": "claimer", "indexed": true},
      {"type": "uint256", "name": "amount", "indexed": false}
    ]
  },
  {
    "type": "error",
    "name": "AlreadyClaimed",
    "inputs": [{"type": "address", "name": "claimer"}]
  },
  {
    "type": "error", 
    "name": "FaucetPaused",
    "inputs": []
  }
]
```

## UI Flow

1. **Parse Deep Link**: Extract `chainId`, `faucet`, `token`, `amount`, `decimals`
2. **Connect Wallet**: Ensure user wallet is connected to correct chain
3. **Check Eligibility**: Call `hasClaimed(userAddress)` - show "Already Claimed" if true
4. **Show Claim UI**: Display "Claim {amount} tokens" button
5. **Execute Claim**: Call `writeContract()` with faucet address and `claim()` function
6. **Handle Result**: 
   - Success: Show minted amount, update UI to "Claimed"
   - `AlreadyClaimed`: Show "Already claimed" message
   - `FaucetPaused`: Show "Faucet temporarily unavailable"

## Error Handling

- `AlreadyClaimed(address)`: User already claimed tokens
- `FaucetPaused()`: Faucet is paused by DAO  
- `GlobalCapExceeded(uint256, uint256)`: Faucet has no tokens left
- Standard transaction errors: insufficient gas, user rejection, etc.

## State Queries

```typescript
// Check if user already claimed
const alreadyClaimed = await readContract({
  address: faucet,
  abi: faucetABI,
  functionName: 'hasClaimed',
  args: [userAddress]
})

// Get remaining tokens available
const remaining = await readContract({
  address: faucet,
  abi: faucetABI, 
  functionName: 'remainingTokens'
})
```