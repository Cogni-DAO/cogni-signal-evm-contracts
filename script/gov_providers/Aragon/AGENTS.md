# Aragon OSx Provider - Token Voting Plugin

Deploys production-ready Aragon OSx DAO with Token Voting Plugin for token-based governance.

## Files

**AragonOSxProvider.sol** - Implements IGovProvider for Aragon OSx with Token Voting  
**AragonInterfaces.sol** - Official Aragon OSx contract interfaces and struct definitions

## Input Requirements

- **WALLET_PRIVATE_KEY**: Deployment wallet private key
- **EVM_RPC_URL**: Sepolia RPC endpoint  
- **TOKEN_INITIAL_HOLDER**: Address to receive initial governance tokens
- **GOV_PROVIDER**: Set to "aragon-osx"

## Output

- **DAO_ADDRESS**: Main Aragon DAO contract
- **MULTISIG_PLUGIN_ADDRESS**: Token Voting plugin contract (reuses field name for compatibility)
- **SIGNAL_CONTRACT**: CogniSignal contract address
- **CHAIN_ID**: Network chain ID (11155111 for Sepolia)

## Token Voting Configuration

**Voting Settings:**
- Voting Mode: Standard (0)
- Support Threshold: 50% (500000)
- Min Participation: 50% (500000) 
- Min Duration: 3600 seconds (1 hour)
- Min Proposer Voting Power: 1 token

**Token Settings:**
- New governance token created (not existing token)
- Token name/symbol from config
- Initial holder receives 1 token

## Network Support

- **Sepolia**: Full support with official contracts
- Uses official Aragon OSx DAOFactory and Token Voting plugin
- **Token Voting Plugin Repository**: `0x424F4cA6FA9c24C03f2396DF0E96057eD11CF7dF`

## Critical Debugging Information

### Current Issue: minDuration Encoding Bug

**PROBLEM**: TokenVotingSetup reverts because minDuration appears as 0xE1 (225s) in calldata instead of 0xE10 (3600s)  
**CONSTRAINT**: Aragon requires minDuration >= 3600 seconds (1 hour minimum)  
**STATUS**: Struct encoding issue, NOT parameter count or missing fields

### Parameter Structure (3 Structs Required)

**TokenVotingSetup::prepareInstallation()** expects exactly 3 struct parameters:

1. **VotingSettings** (from MajorityVotingBase.sol):
   ```solidity
   struct VotingSettings {
       VotingMode votingMode;        // 0=Standard, 1=EarlyExecution, 2=VoteReplacement  
       uint32 supportThreshold;      // 500000 = 50%
       uint32 minParticipation;      // 500000 = 50%
       uint64 minDuration;           // >=3600 seconds (CRITICAL: must encode as 0xE10)
       uint256 minProposerVotingPower; // 1e18 for 18-decimal tokens
   }
   ```

2. **TokenSettings** (from TokenVotingSetup.sol):
   ```solidity
   struct TokenSettings {
       address addr;     // address(0) = deploy new GovernanceERC20
       string name;      // token name
       string symbol;    // token symbol
   }
   ```

3. **MintSettings** (from GovernanceERC20.sol):
   ```solidity
   struct MintSettings {
       address[] receivers;          // token recipients
       uint256[] amounts;            // amounts in wei (1e18 for 1 token)
       bool ensureDelegationOnMint;  // true for voting power
   }
   ```

### Debugging Workflow

**Step 1: Verify Encoding**
```bash
# Check that uint64(3600) encodes as 0xE10 not 0xE1
cast abi-encode "uint64" 3600
# Expected: 0x0000000000000e10
```

**Step 2: Decode Calldata**
```bash
# Decode your actual calldata to see field values
cast abi-decode "(uint8,uint32,uint32,uint64,uint256),(address,string,string),(address[],uint256[],bool)" <hex_data>
```

**Step 3: Check Struct Alignment**
- Import official structs: `import {VotingSettings} from "token-voting-plugin/src/base/MajorityVotingBase.sol"`
- Never redefine structs locally
- Verify field order matches official source exactly

**Step 4: Test Without Gas**
```bash
# Fork testnet for zero-cost debugging
cast call --rpc-url $RPC_URL $TOKEN_VOTING_SETUP "prepareInstallation(address,bytes)" $DAO_ADDRESS $ENCODED_DATA
```

## Web3 Development Patterns

### Dependency Management
- **Version Compatibility**: Aragon OSx requires OpenZeppelin v4.9.5, not v5.x
- **Remapping Debug**: Use `forge build --dry-run` to verify imports resolve correctly
- **Nested Dependencies**: Check lib/ subdirectories for version conflicts

### Struct Compatibility 
- **Import Official Types**: Always use source contracts, never local definitions
- **ABI Verification**: Use `cast interface <address>` to verify deployed contracts
- **Encoding Test**: Validate `abi.encode()` output before deployment

### Empty Revert Debugging
- **Fork Networks**: Use Tenderly/Anvil for zero-cost debugging
- **Console Logging**: Add debug logs before failure points
- **Revert Decoding**: Use `cast` to decode revert data patterns

### Parameter Validation
- **Constraint Checking**: Verify minDuration >= 3600, token amounts in wei
- **Type Casting**: Use explicit uint64(3600) to prevent truncation
- **Field Alignment**: Check that struct fields encode to expected hex values

## Resource Discovery Links

### When to Use Each Resource

**For Struct Definitions & Constraints**:
- **Token Voting API Docs**: https://docs.aragon.org/token-voting/1.x/index.html → Use for minDuration limits (≥1 hour)
- **MajorityVotingBase.sol**: https://github.com/aragon/token-voting-plugin/blob/main/src/base/MajorityVotingBase.sol → Use for VotingSettings field order
- **TokenVotingSetup.sol**: https://github.com/aragon/token-voting-plugin/blob/main/src/TokenVotingSetup.sol → Use for parameter structure
- **GovernanceERC20.sol**: https://github.com/aragon/token-voting-plugin/blob/main/src/erc20/GovernanceERC20.sol → Use for MintSettings

**For Debugging Failed Installations**:
- **Plugin Installation Guide**: https://ethereum.stackexchange.com/questions/147798/how-do-i-install-my-custom-plugin-into-an-aragon-dao → Use when plugin setup fails
- **OSx Plugin Development**: https://devs.aragon.org/docs/how-to-guides/plugin-development → Use for setup troubleshooting

**For Contract Verification**:
- **Sepolia Token Voting Repo**: https://sepolia.etherscan.io/address/0x424F4cA6FA9c24C03f2396DF0E96057eD11CF7dF → Use to verify deployment addresses
- **NPM Artifacts**: `@aragon/token-voting-plugin-artifacts` → Use for ABI verification

### Essential Debugging Commands

```bash
# Verify uint64 encoding (should be 0x0000000000000e10 for 3600)
cast abi-encode "uint64" 3600

# Get plugin setup ABI for parameter debugging  
cast interface 0x7870837ffe670E62d4e601393D454f1b8649F7f9 --rpc-url $EVM_RPC_URL

# Test parameter encoding without deployment
cast call $TOKEN_VOTING_SETUP "prepareInstallation(address,bytes)" $DAO_ADDR $DATA --rpc-url $EVM_RPC_URL

# Decode actual calldata to verify field values
cast abi-decode "(uint8,uint32,uint32,uint64,uint256),(address,string,string),(address[],uint256[],bool)" <your_hex_data>
```

## Environment Variable Changes

All .env loading must happen in the parent script/SetupDevChain.s.sol. Although it might be possible to do in Aragon-specific files, this has proven problematic in the past.

## Integration Notes

- Token-based governance: Holders vote on proposals with voting power based on token balance
- E2E flow: Create proposal → Vote (reach thresholds) → Execute approved actions  
- Member management: Transfer governance tokens to add/remove voting members
- Minimum requirements enforced: minDuration >= 3600 seconds

## Resources

- Installing custom plugin in an existing DAO: https://ethereum.stackexchange.com/questions/147798/how-do-i-install-my-custom-plugin-into-an-aragon-dao?utm_source=chatgpt.com

- Aragon Docs: Token Voting: https://docs.aragon.org/token-voting/1.x/api/TokenVoting
- Aragon Source: https://github.com/aragon/token-voting-plugin/tree/main/npm-artifacts
Use these exact sources for types and param order: TokenVotingSetup.sol, MajorityVotingBase.sol, DAOFactory.sol, PluginSetupProcessor.sol, and GovernanceERC20.sol — https://github.com/aragon/token-voting-plugin/blob/main/src/TokenVotingSetup.sol
- https://github.com/aragon/token-voting-plugin/blob/main/src/base/MajorityVotingBase.sol
- https://github.com/aragon/osx/blob/develop/packages/contracts/src/framework/dao/DAOFactory.sol
- https://github.com/aragon/osx/blob/develop/packages/contracts/src/framework/plugin/setup/PluginSetupProcessor.sol
- https://github.com/code-423n4/2023-03-aragon/blob/main/packages/contracts/src/token/ERC20/governance/GovernanceERC20.so
