# Deployment Scripts

## SetupDevChain.s.sol

Deploys governance stack with modular provider system.

### Architecture
1. **Governance Provider** - Pluggable DAO framework support
2. **DAO Contract** - Framework-specific implementation  
3. **Governance Token** - ERC20 voting token (created by provider)
4. **CogniSignal** - Event aggregation contract

### Provider System
- `GOV_PROVIDER=aragon-osx` (default) - Aragon OSx with TokenVoting plugin
- `GOV_PROVIDER=simple` - SimpleDAO fallback

### Usage
```bash
make dao-setup
```

**Required:**
- `WALLET_PRIVATE_KEY` - Funded Sepolia wallet
- `EVM_RPC_URL` - Sepolia RPC endpoint  
- `ETHERSCAN_API_KEY` - Contract verification
- `TOKEN_INITIAL_HOLDER` - Address to receive initial tokens

**Optional:**
- `GOV_PROVIDER` - Provider type (default: "aragon-osx")
- `TOKEN_NAME/SYMBOL/SUPPLY` - Token configuration

### Output

Generates `.env.{TOKEN_SYMBOL}` file with:
- `SIGNAL_CONTRACT` - CogniSignal address
- `DAO_ADDRESS` - DAO contract
- `ARAGON_VOTING_PLUGIN_CONTRACT` - Voting plugin (if Aragon)
- `CHAIN_ID` - Network ID

### Provider Configuration

Script loads Aragon addresses from artifacts:
- DAOFactory: `0xB815791c233807D39b7430127975244B36C19C8e` 
- PluginSetupProcessor: `0xC24188a73dc09aA7C721f96Ad8857B469C01dC9f`
- TokenVotingRepo: `0x424F4cA6FA9c24C03f2396DF0E96057eD11CF7dF`

Addresses passed via `providerSpecificConfig` field to providers.

## Deploy.s.sol

Deploys CogniSignal with existing DAO.

```bash
make deploy-contract
```

**Required:** `DAO_ADDRESS`, `WALLET_PRIVATE_KEY`, `EVM_RPC_URL`, `ETHERSCAN_API_KEY`