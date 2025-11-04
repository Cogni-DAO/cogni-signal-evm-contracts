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

## NonTransferableVotes.sol

Non-transferable governance token preventing secondary markets while enabling 1-person-1-vote.

### Key Features
- **Transfer Prevention**: Reverts on user-to-user transfers (allows mint/burn only)
- **One Token Limit**: Enforces exactly 1e18 tokens per address maximum
- **Auto-Delegation**: Self-delegates on mint (voting power active immediately)
- **Minter Roles**: Owner-controlled `mapping(address => bool) minters` for authorized contracts

### Core Functions
```solidity
function mint(address to, uint256 amount) external;       // Mints exactly 1e18 if authorized
function grantMintRole(address account) external onlyOwner;  // Grant minter permission
function revokeMintRole(address account) external onlyOwner; // Revoke minter permission
```

### Access Control
- **Owner**: DAO (set via `transferOwnership` after deployment)
- **Minters**: Authorized contracts (faucets, other systems) granted by owner
- **Enforcement**: `require(msg.sender == owner() || minters[msg.sender])`

### Token Constraints
```solidity
require(amount == 1e18, "Must mint exactly 1e18");           // Fixed unit
require(balanceOf(to) == 0, "Address already has 1");         // One-and-done
```

### Integration
- Compatible with Aragon TokenVoting plugin (implements ERC20Votes)
- FaucetMinter requests minter role via DAO proposal: `token.grantMintRole(faucet)`
- Owner can revoke minter access to disable systems

## FaucetMinter.sol

Token faucet enabling one-time governance token claims with DAO-controlled configuration.

### Key Features
- **One-Time Claims**: `mapping(address => bool) claimed` prevents duplicate claims
- **DAO Control**: `DaoAuthorizable` enables DAO-only pause and configuration
- **Reentrancy Protection**: `ReentrancyGuard` prevents reentrancy attacks
- **Global Cap**: Limits total tokens that can be minted

### Core Functions
```solidity
function claim() external nonReentrant;              // Mint tokens to msg.sender
function pause(bool _paused) external auth(PAUSE_PERMISSION);  // DAO pause control
function setAmountPerClaim(uint256) external auth(CONFIG_PERMISSION);
function setGlobalCap(uint256) external auth(CONFIG_PERMISSION);
```

### Token Integration
- Calls `token.mint(msg.sender, amountPerClaim)` on claim
- Requires minter role on NonTransferableVotes token
- DAO grants minter role via: `token.grantMintRole(faucetAddress)`