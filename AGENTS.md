# CogniSignal Contract System

## Overview
On-chain governance events for VCS operations via [cogni-git-admin](https://github.com/Cogni-DAO/cogni-git-admin).

## Deployment
`make dao-setup` deploys governance stack with automatic verification on Sepolia.

## Architecture  
Modular governance providers enable different DAO frameworks while maintaining stable CogniSignal interface.

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

## Empty Revert Data Debugging

### Causes

1. **Swallowing Revert Data on Low-Level Calls**
   ```solidity
   // BAD: Discards revert data
   (bool success, bytes memory data) = target.call(callData);
   require(success, "Call failed"); // Loses the actual error!
   
   // GOOD: Bubble revert data
   (bool success, bytes memory data) = target.call(callData);
   assembly {
       if iszero(success) {
           revert(add(data, 0x20), mload(data)) // Bubble exact bytes
       }
   }
   ```

2. **Proxy/Fallback Not Bubbling Returndata**
   ```solidity
   // BAD: Proxy swallows revert data
   fallback() external payable {
       (bool success,) = implementation.delegatecall(msg.data);
       require(success, "Delegate failed"); // Lost revert data!
   }
   
   // GOOD: Proxy bubbles revert data  
   fallback() external payable {
       (bool success, bytes memory data) = implementation.delegatecall(msg.data);
       assembly {
           if iszero(success) {
               revert(add(data, 0x20), mload(data))
           }
           return(add(data, 0x20), mload(data))
       }
   }
   ```

3. **No Reason Provided**
   ```solidity
   // BAD: Zero revert data
   require(condition);        // Empty revert
   revert();                 // Empty revert
   
   // GOOD: Always provide context
   require(condition, "Specific failure reason");
   revert CustomError(param1, param2);
   ```

4. **Using transfer/send Instead of call**
   ```solidity
   // BAD: No revert data from failed transfers
   payable(recipient).transfer(amount);  // Boolean failure only
   
   // GOOD: Use call for revert data
   (bool success, bytes memory data) = payable(recipient).call{value: amount}("");
   if (!success) {
       assembly { revert(add(data, 0x20), mload(data)) }
   }
   ```

### Practices

**Custom Errors**:
```solidity
error NotAllowed(address who, uint256 id);
if (!authorized) revert NotAllowed(msg.sender, tokenId);
```

**Bubble Revert Data**:
```solidity
Address.functionCall(target, callData);
```

### Diagnostic Checklist

1. **Search for `require(success, "…")` after low-level calls** → Replace with bubbling pattern
2. **If using proxy, verify fallback returns returndata exactly** → Add assembly bubbling  
3. **Grep for `transfer(` or `send(`** → Replace with `call{value:}("")`
4. **Ensure compiler ≥0.8.4 and tests decode custom errors** → Update test patterns
5. **Add `returndatasize()` logging** → Confirm bytes exist before being dropped

**Debug**: `cast call --rpc-url $RPC_URL $CONTRACT "function(params)" <args>`

