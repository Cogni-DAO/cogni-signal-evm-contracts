# HANDOFF: Non-Transferable Governance Token Implementation

## OBJECTIVE
Converting governance tokens from **transferable** to **non-transferable** to prevent trading while maintaining voting functionality and faucet compatibility.

## WHAT WE'RE IMPLEMENTING

**Problem Solved:** Current `GovernanceERC20` tokens can be transferred/traded, allowing market speculation. We want "1 person = 1 vote" with no secondary markets.

**Solution:** Custom `NonTransferableVotes` token that:
- ✅ **Blocks transfers** between users (reverts on user-to-user transfers)  
- ✅ **Allows minting/burning** (from/to address(0))
- ✅ **Maintains voting** (auto-delegates on mint, compatible with Aragon TokenVoting)
- ✅ **Works with existing faucet** (same `mint(address, uint256)` interface)

## IMPLEMENTATION APPROACH

**Key Insight:** Deploy custom token first, then tell Aragon to use it instead of creating its own.

**Files Modified:**
1. **`src/NonTransferableVotes.sol`** - New non-transferable token contract
2. **`script/gov_providers/Aragon/AragonOSxProvider.sol`** - Modified to use custom token
3. **`script/SetupDevChain.s.sol`** - Updated faucet amount to 1e18 (1 full token)

**Deployment Flow:**
```
1. Deploy NonTransferableVotes (deployer as temp owner)
2. Create DAO with tokenSettings.addr = customToken 
3. Initialize DAO in token + transfer ownership: token.initializeDao(dao)
```

## CURRENT STATUS

### ✅ COMPLETED
- **NonTransferableVotes contract** - Core logic implemented
- **AragonOSxProvider integration** - Modified to use custom token
- **Permission system** - DAO-controlled minting via `MINT_PERMISSION_ID`
- **Compilation fixes** - Resolved OpenZeppelin inheritance issues

### 🚫 CURRENT BLOCKER

**`.env` file not found** - Script can't find base environment configuration:
```bash
make dao-setup
# Error: Makefile:4: .env: No such file or directory
```

**Expected:** `.env` should contain base config (keys, RPC URLs, etc.)  
**Reality:** Script looking for `.env` but only generated files exist (`.env.CogniFaucet`, `.env.CogniMinter`)

**Files to check:**
- `/Users/derek/dev/cogni-gov-contracts/.env` (missing?)
- `/Users/derek/dev/cogni-gov-contracts/.env.CogniFaucet` (generated output)
- `/Users/derek/dev/cogni-gov-contracts/.env.CogniMinter` (generated output)  
- `/Users/derek/dev/cogni-gov-contracts/Makefile:4` (what does line 4 expect?)

## KEY FILES

### Core Implementation
- **`src/NonTransferableVotes.sol`** - Non-transferable token with DAO permissions
- **`script/gov_providers/Aragon/AragonOSxProvider.sol:134-206`** - Custom token deployment + DAO init

### Original Contracts (reference)
- **`src/FaucetMinter.sol`** - Works unchanged (same mint interface)
- **`lib/token-voting-plugin/src/erc20/GovernanceERC20.sol`** - Original transferable token

### Config/Environment  
- **`script/SetupDevChain.s.sol:93-94`** - Faucet amount (now 1e18)
- **`FAUCET-INTEGRATION.md`** - Integration docs (unchanged)
- **`AGENTS.md:75-86`** - Token faucet documentation

## NEXT STEPS

1. **Fix .env issue** - Investigate why Makefile can't find base environment
2. **Test deployment** - Run `make dao-setup` with non-transferable token
3. **Verify functionality:**
   - Token blocks transfers: `token.transfer()` should revert
   - Faucet works: `faucet.claim()` should mint tokens  
   - Voting works: Check TokenVoting compatibility
4. **Update sister repo** - Fix permission IDs in `cogni-proposal-launcher/src/pages/propose-faucet.tsx`

## CONTEXT LINKS
- **Permission ID mismatch issue:** Sister repo uses wrong hardcoded permission IDs
- **Faucet debugging:** Existing faucet `0x3963A719e61BCF8E76fC0A92Cc7635A2134A0592` has wrong permissions
- **Original analysis:** Found in conversation about making tokens non-transferable

The architecture is sound, implementation is complete, just needs environment setup to test deployment.