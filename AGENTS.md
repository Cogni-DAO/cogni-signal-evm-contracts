# AGENTS.md — cogni-signal-evm-contracts

## Purpose
Emit deterministic on-chain events that authorize specific admin actions in GitHub via the cogni-admin app. Keep governance thin and auditable.

## Scope
- Chain: EVM only.
- Contract: minimal `CogniSignal` callable only by the DAO (or OSx permissioned later).
- Output: `CogniAction` event with a stable schema.
- Out of scope: Solana, treasury, generic plugins, UI.

## Core Actions (v1)
- `PR_APPROVE`
- `MERGE` (later)
- `LABEL` (later)
- `REVERT` (later)

All via: signal(repo, action, target, pr, commit, extra)

Event fields: dao, chainId, repo, action, target, pr, commit, extra(bytes: abi.encode(nonce, deadline, paramsJson))


## Interfaces
- **Input:** DAO executes `signal(...)`.
- **Output:** `CogniAction` event consumed by cogni-admin.
- **Mapping:** `(dao, contract, chainId) -> allowed repos` kept off-chain for MVP.

**Note:** Off Chain webhook listeners (via Alchemy, Quicknode, etc) must be set up to listen for this signal execution.

## Security Invariants
- Only the DAO may call `signal()`.
- Off-chain verifier enforces `(dao, contract, chainId, repo, nonce, deadline, commit)` and replay protection.
- GitHub App holds required admin permissions.

## Repo Rules
- Minimal Solidity. No stateful side effects beyond events.
- Tests cover auth and event payload fidelity.
- Scripts for deploy; optional OSx install/grant scripts later.

## Roadmap
1. v1: `onlyDAO` + events + off-chain nonce checks.
2. v1.1: OSx permission gates; on-chain repo allowlist.
3. v1.2: add `MERGE`, `LABEL`, `REVERT`.
4. v2: schema version bump `cogni.action@2` if fields change.
