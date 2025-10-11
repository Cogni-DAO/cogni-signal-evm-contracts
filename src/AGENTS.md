# Source Code

## CogniSignal.sol

Minimal DAO-only contract that emits `CogniAction` events for GitHub governance operations.

### Key Features
- **Access Control**: `onlyDAO` modifier restricts all calls
- **Event Emission**: Single `CogniAction` event with governance data
- **No State**: Event-only contract with no storage beyond immutable DAO address

### Function
```solidity
function signal(
    string calldata repo,     // Target GitHub repository
    string calldata action,   // Action type (e.g. "PR_APPROVE")
    string calldata target,   // Action target
    uint256 pr,               // Pull request number  
    bytes32 commit,           // Git commit hash
    bytes calldata extra      // ABI-encoded additional data
) external onlyDAO
```

### Security
- Only the DAO address (set at deployment) can call `signal()`
- Contract verified on Etherscan for transparency
- No upgrades or admin functions