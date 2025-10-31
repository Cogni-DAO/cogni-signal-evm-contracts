# Source Code

## CogniSignal.sol

Generic VCS governance contract that emits `CogniAction` events for multi-provider operations.

### Key Features
- **Access Control**: `onlyDAO` modifier restricts all calls
- **Multi-VCS Support**: Works with GitHub, GitLab, self-hosted Git
- **Generic Schema**: Provider-agnostic action routing
- **No State**: Event-only contract with no storage beyond immutable DAO address

### Function
```solidity
function signal(
    string calldata vcs,       // "github" | "gitlab" (future: "gerrit" | "radicle")
    string calldata repoUrl,   // Full VCS URL
    string calldata action,    // e.g. "merge", "grant", "revoke"
    string calldata target,    // e.g. "change", "collaborator", "branch"
    string calldata resource,  // e.g. "42" (PR number) or "alice" (username)
    bytes  calldata extra      // ABI-encoded: (nonce, deadline, paramsJson)
) external onlyDAO
```

### VCS Provider Mapping
- **GitHub**: `vcs="github"`, `repoUrl="https://github.com/owner/repo"`, `resource="{PR number}"`
- **GitLab**: `vcs="gitlab"`, `repoUrl="https://gitlab.com/owner/repo"`, `resource="{MR IID}"`
- **Future**: `vcs="gerrit"`, `vcs="radicle"` for additional VCS providers

### Security
- Only the DAO address (set at deployment) can call `signal()`
- Contract verified on Etherscan for transparency
- No upgrades or admin functions

## FaucetMinter.sol

Token faucet enabling one-time governance token claims with DAO-controlled configuration.

### Key Features
- **One-Time Claims**: `mapping(address => bool) claimed` prevents duplicate claims
- **DAO Control**: `DaoAuthorizable` enables DAO-only pause and configuration
- **Reentrancy Protection**: `ReentrancyGuard` prevents reentrancy attacks
- **Global Cap**: Limits total tokens that can be minted
- **Custom Errors**: Gas-efficient error handling with context

### Core Functions
```solidity
function claim() external nonReentrant;              // Mint tokens to msg.sender
function pause(bool _paused) external auth(PAUSE_PERMISSION);  // DAO pause control
function setAmountPerClaim(uint256) external auth(CONFIG_PERMISSION);
function setGlobalCap(uint256) external auth(CONFIG_PERMISSION);
```

### Permission Requirements
- **MINT_PERMISSION_ID**: Faucet needs this permission on the GovernanceERC20 token
- **PAUSE_PERMISSION**: DAO needs this permission on faucet for pause control
- **CONFIG_PERMISSION**: DAO needs this permission on faucet for configuration

### Events
```solidity
event Claimed(address indexed claimer, uint256 amount);
event PauseToggled(bool paused);
event AmountPerClaimUpdated(uint256 oldAmount, uint256 newAmount);
event GlobalCapUpdated(uint256 oldCap, uint256 newCap);
```

### Error Conditions
- `AlreadyClaimed(address)`: User has already claimed tokens
- `FaucetPaused()`: Faucet is currently paused
- `GlobalCapExceeded(uint256, uint256)`: Request exceeds available tokens
- `ZeroAmount()`: Cannot set zero amount per claim
- `InvalidCap(uint256)`: Cap is invalid (below current minted amount)

### Integration with Aragon OSx
1. Uses official `GovernanceERC20.MINT_PERMISSION_ID`
2. DAO grants `MINT_PERMISSION_ID` to faucet via `dao.grant(token, faucet, permissionId)`
3. DAO can revoke permission to halt faucet: `dao.revoke(token, faucet, permissionId)`
4. Works with existing TokenVoting governance setup