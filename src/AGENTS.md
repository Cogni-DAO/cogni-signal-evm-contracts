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