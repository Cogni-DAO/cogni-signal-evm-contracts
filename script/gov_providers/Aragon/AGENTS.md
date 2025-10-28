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

### TokenVotingSetup Parameter Structure

**CRITICAL**: The `TokenVotingSetup::prepareInstallation()` function expects exactly 3 struct parameters:

1. **VotingSettings struct** (5 fields):
   ```solidity
   struct VotingSettings {
       VotingMode votingMode;        // enum (0=Standard, 1=EarlyExecution, 2=VoteReplacement)
       uint32 supportThreshold;      // e.g., 500000 (50%)
       uint32 minParticipation;      // e.g., 500000 (50%)
       uint64 minDuration;           // minimum 3600 seconds
       uint256 minProposerVotingPower; // e.g., 1
   }
   ```

2. **TokenSettings struct** (3 fields):
   ```solidity
   struct TokenSettings {
       address addr;     // existing token address (use address(0) for new token)
       string name;      // token name
       string symbol;    // token symbol
       // NOTE: NO decimals field - this was a key debugging discovery
   }
   ```

3. **MintSettings struct** (2 arrays):
   ```solidity
   struct MintSettings {
       address[] receivers;  // array of addresses to receive tokens
       uint256[] amounts;    // corresponding amounts for each receiver
   }
   ```

### Parameter Encoding Pattern

**CORRECT**:
```solidity
bytes memory tokenVotingData = abi.encode(
    votingSettings,    // Complete VotingSettings struct
    tokenSettings,     // Complete TokenSettings struct  
    mintSettings       // Complete MintSettings struct
);
```

**INCORRECT** (causes empty revert data):
```solidity
bytes memory tokenVotingData = abi.encode(
    uint8(0), uint32(600000), uint32(500000), uint64(3600), uint256(1), // Individual fields
    address(0), config.tokenName, config.tokenSymbol,                    // Individual fields
    receivers, amounts                                                    // Arrays
);
```

## Resource Discovery Links

### Official Aragon Documentation
- **Token Voting Plugin**: https://devs.aragon.org/docs/token-voting-plugin
- **Plugin Development**: https://devs.aragon.org/docs/how-to-guides/plugin-development
- **OSx SDK**: https://devs.aragon.org/docs/sdk

### Contract Artifacts & Source Code
- **NPM Package**: `@aragon/token-voting-plugin-artifacts`
- **Repository**: https://github.com/aragon/token-voting-plugin
- **Sepolia Deployment**: https://sepolia.etherscan.io/address/0x424F4cA6FA9c24C03f2396DF0E96057eD11CF7dF

### Debugging Tools
- **TokenVotingABI.json**: Generated ABI file in repo root contains struct definitions
- **Cast decode**: `cast abi-decode "prepareInstallation(address,(uint8,address))" <revert_data>`
- **Tenderly**: Fork Sepolia to debug contract calls without gas costs

### Key Debugging Commands

```bash
# Find plugin repository address
npm install @aragon/token-voting-plugin-artifacts
node -e "console.log(require('@aragon/token-voting-plugin-artifacts').addresses.pluginRepo.sepolia)"

# Get TokenVotingSetup ABI
cast interface 0x424F4cA6FA9c24C03f2396DF0E96057eD11CF7dF --etherscan-api-key $ETHERSCAN_API_KEY

# Debug failed transactions
cast call $TOKEN_VOTING_SETUP "prepareInstallation(address,(uint8,address))" $DAO_ADDRESS $ENCODED_DATA --rpc-url $EVM_RPC_URL
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
