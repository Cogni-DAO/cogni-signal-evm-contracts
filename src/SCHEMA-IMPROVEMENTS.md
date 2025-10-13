# CogniSignal Schema Analysis & Improvements

## Current Problems

The existing `CogniSignal` interface (`src/CogniSignal.sol:6-16`) has several design limitations that restrict its extensibility and usability:

### 1. **PR-Centric Design**
- Fields like `uint256 pr` and `bytes32 commit` are hardcoded for pull request operations
- Non-PR actions (user management, repository settings) must abuse these fields with dummy values
- Forces all actions into a PR-shaped hole regardless of semantic meaning

### 2. **Poor Parameter Encoding** 
- Username data hex-encoded in `bytes extra` is error-prone and not type-safe
- Manual hex encoding/decoding creates opportunities for bugs
- No standardized way to encode different data types

### 3. **Inflexible Schema**
- New action types require either:
  - Abusing existing fields with dummy values (`pr=0, commit=bytes32(0)`)
  - Contract upgrades to add new fields
- Cannot support complex nested data structures

### 4. **Resource Wasteful**
- All events emit unused fields set to zero/empty values
- Gas inefficient for non-PR operations
- Storage overhead for irrelevant data

## Proposed Solution: Structured Action Schema

Replace the rigid field structure with a flexible, typed approach using ABI-encoded parameters.

### Core Design

```solidity
event CogniActionV1(
    address indexed dao,
    uint64  indexed srcChainId,
    bytes32 indexed repoId,     // keccak256("provider:owner/repo")
    bytes32 provider,           // keccak256("github")
    bytes32 resourceKind,       // keccak256("pr" | "collaborator" | ...)
    bytes32 action,             // keccak256("merge" | "grant" | ...)
    bytes   resourceId,         // ABI-encoded id (number or string)
    bytes32 idHash,             // keccak256(resourceId) for indexing
    bytes   meta,               // abi.encode(ActionMetaV1)
    address indexed executor
);
```

### Key Benefits

1. **Extensible**: New actions without contract changes
2. **Type-Safe**: Proper ABI encoding prevents encoding errors  
3. **Gas-Efficient**: Binary encoding vs string manipulation
4. **Developer-Friendly**: Standard ABI tooling support
5. **Future-Proof**: Supports complex data types as needed

### Implementation Approach

**Dual Interface Design:**
- `signalText()` - Human-friendly string interface for manual use (Aragon UI, cast)
- `signalPR()`, `signalCollaborator()` - Type-safe helpers for common actions

**Off-Chain Handling:**
- Router keys on `(provider, resourceKind, action)` tuple
- Resource ID interpretation based on `resourceKind`:
  - `kind=="pr"` ’ `resourceId` is ABI-encoded `uint256`
  - `kind=="collaborator"` ’ `resourceId` is UTF-8 username bytes
- JSON parameters in `meta.params` for human-readable config

### Migration Strategy

1. Deploy new contract alongside existing one
2. Update cogni-git-admin to handle both event formats
3. Migrate DAO governance to use new contract
4. Deprecate old contract after transition period

## Result

This design eliminates the current schema's rigidity while maintaining backward compatibility and human usability. Actions become self-describing through the structured approach, enabling rich governance operations beyond simple PR management.