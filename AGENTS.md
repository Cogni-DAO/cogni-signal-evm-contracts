# CogniSignal Contract System

## Overview
On-chain governance events for VCS operations via [cogni-git-admin](https://github.com/Cogni-DAO/cogni-git-admin).

## Deployment
`make dao-setup` deploys governance stack + **unpermissioned faucet** with automatic verification on Sepolia.

## Architecture  
Modular governance providers enable different DAO frameworks while maintaining stable CogniSignal interface.

Cross-chain governance configuration system supports Aragon OSx TokenVoting, OpenZeppelin Governor, and Solana Realms via standardized config schema.

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
# Faucet needs DAO proposal to mint tokens (see script/GrantMintToFaucet.s.sol)
```

See `README.md` for detailed setup instructions.

## Token System

**NonTransferableVotes** - Custom ERC20Votes token preventing secondary markets while enabling governance.

**Key Features:**
- Blocks all user-to-user transfers (prevents trading)  
- Enforces exactly 1e18 tokens per address (1-person-1-vote)
- Auto-delegates on mint (voting power active immediately)
- Owner-controlled minter roles for authorized contracts

## Token Faucet

**FaucetMinter.sol** - Anyone claims exactly 1 governance token, once per wallet.

**Setup Flow:**
1. Deploy faucet (unauthorized initially)
2. Create DAO proposal: `token.grantMintRole(faucet)`  
3. After approval, faucet operational via minter role

**Integration:**
- `cogni-proposal-launcher` creates deeplink for minter role proposal

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

## Cross-Chain Governance Configuration

### Universal GovConfig Schema

Standardized configuration supporting Aragon OSx TokenVoting, OpenZeppelin Governor, and Solana Realms:

```yaml
org:
  name: string                         # DAO name/title
  metadataURI: string                  # IPFS metadata link

governance_model:
  type: token_voting | address_list | council | multisig
  module_version: string               # Provider-specific version

token_spec:
  mode: create_new | existing          # Token deployment strategy
  mint_or_token_address: address       # Token address or mint authority
  symbol: string                       # Token symbol
  decimals: uint8                      # Token decimals
  delegation: bool                     # Enable vote delegation

initial_holders:
  - address: address                   # Initial token holders
    amount: uint256                    # Token amounts

voting_params:
  support_threshold_pct: uint32        # Majority threshold (0-1e6 or %)
  quorum_pct: uint32                   # Minimum participation quorum
  proposal_threshold: uint256          # Min votes to create proposals
  voting_delay: uint64                 # Delay before voting starts
  voting_period: uint64                # Voting duration
  early_execution: bool                # Enable early execution/tipping
  vote_replacement: bool               # Allow changing votes

executive_params:
  timelock_delay: uint64               # Execution delay (if applicable)

membership_filters:
  allowlist: address[]                 # Permitted addresses (optional)
  blocklist: address[]                 # Blocked addresses (optional)
  excluded_accounts: address[]         # Excluded from governance

treasury:
  treasury_accounts: address[]         # DAO treasury addresses

admin_emergency:
  guardian_multisig: address           # Emergency guardian/veto power

chain:
  network_id_or_cluster: string        # Network identifier
  required_program_or_plugin_version: string  # Version requirements
```

### Provider Compatibility Matrix

| Field | Aragon OSx | OpenZeppelin | Solana Realms |
|-------|------------|--------------|---------------|
| org metadata | ✓ DAO metadata | App-level | ✓ Realm metadata |
| token voting | ✓ Plugin | ✓ IVotes | ✓ Community/council |
| delegation | ✓ IVotes | ✓ Native | ✓ Via add-ins |
| support_threshold | ✓ supportThreshold | Via counting | - |
| quorum | ✓ minParticipation | ✓ quorum() | ✓ |
| proposal_threshold | ✓ minProposerVotingPower | ✓ proposalThreshold | ✓ |
| voting_delay | Mode-dependent | ✓ votingDelay | ✓ |
| voting_period | ✓ minDuration | ✓ votingPeriod | ✓ |
| early_execution | ✓ Early exec mode | Via timelock bypass | ✓ Vote tipping |
| vote_replacement | ✓ Vote replacement | Not standard | No |
| timelock | Via permissions | ✓ TimelockController | ✓ Via authorities |

### Implementation Notes

**Current vs Target:**
- Current `IGovProvider.GovConfig` has basic token params only
- Target schema adds comprehensive governance parameters
- Use `providerSpecificConfig` for provider-specific extensions
- Maintain backward compatibility during migration

**Provider-Specific Extensions:**
- **Aragon**: PluginRepo versions, execution modes, permission layers
- **OpenZeppelin**: Timelock toggles, counting modules, extension flags  
- **Solana**: Add-ins for voter-weight, realm configs, program IDs

**Migration Strategy:**
1. Extend `GovConfig` struct incrementally
2. Keep existing simple providers functional
3. Add comprehensive config validation
4. Provider factory handles config mapping

## Repository Architecture

Cross-chain governance requires separate repositories for clean separation:

### cogni-gov-config
- Shared GovConfig schema definitions
- Configuration examples and templates
- Schema validation logic
- Language-agnostic specification

### cogni-evm-smart-contracts  
- CogniSignal core contract
- EVM provider adapters (Aragon OSx, OpenZeppelin Governor)
- Foundry deployment scripts and tests
- Current `cogni-gov-contracts` evolved

### cogni-solana-contracts
- Realms/SPL Governance adapter programs
- Solana program IDs and deployment helpers
- Anchor/native program development
- Cross-program invocation logic

### ++ more DAO chain providers, such as SovereignNetwork

**Rationale:** Clean separation by specification vs EVM vs Solana implementation with minimal coupling between chains and maximum reusability of the shared configuration schema.

