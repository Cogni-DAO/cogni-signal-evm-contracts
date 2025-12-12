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

DAO-controlled membership via join requests and batch approvals.

### Key Features
- **Join Requests**: `mapping(address => bool) requested` tracks membership requests
- **DAO Approval**: Batch approval/rejection via DAO proposal execution
- **Reentrancy Protection**: `ReentrancyGuard` prevents reentrancy attacks
- **Global Cap**: Limits total tokens that can be minted

### Core Functions
```solidity
function requestJoin() external;                     // Request DAO membership
function approve(address[]) external auth(APPROVE_PERMISSION); // DAO approves requests
function reject(address[]) external auth(APPROVE_PERMISSION);  // DAO rejects requests
function pause(bool _paused) external auth(PAUSE_PERMISSION);  // DAO pause control
```

### Join Workflow
1. Users call `requestJoin()` to request membership
2. DAO creates proposal with `approve([addresses])` 
3. Proposal execution mints exactly 1e18 tokens to approved requesters
4. OSx permission grantee is the DAO core (IDAO). Proposals execute as the DAO.

### Token Integration
- Uses `IERC20` interface for token reads and `IMint` interface for minting
- Fixed amount: mints exactly 1e18 tokens per approval (matches token constraint)
- Requires minter role: faucet must be granted `minters[faucet] = true`
- DAO grants via proposal: `token.grantMintRole(faucetAddress)`