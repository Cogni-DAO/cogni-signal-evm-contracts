# Deployment Scripts

## SetupDevChain.s.sol

Deploys complete governance stack with modular provider system.

### Architecture
1. **Governance Provider** - Pluggable DAO framework support
2. **ERC20 Token** - Governance token
3. **DAO Contract** - Framework-specific implementation
4. **CogniSignal** - Event aggregation contract

### Provider System
- `GOV_PROVIDER=aragon` (default) - Aragon OSx with admin plugin
- `GOV_PROVIDER=simple` - Lightweight SimpleDAO fallback

See `script/gov_providers/AGENTS.md` for provider details.

### Usage
```bash
make dao-setup  # Deploys complete stack
```

**Required Environment:**
- `WALLET_PRIVATE_KEY` - Funded Sepolia wallet
- `EVM_RPC_URL` - Sepolia RPC endpoint

**Optional:**
- `GOV_PROVIDER` - Provider type (default: "aragon")
- `TOKEN_NAME/SYMBOL/SUPPLY` - Token configuration

### Output

Generates environment variables for cogni-git-admin:
- Console display for copy/paste
- Saved to `.env.{TOKEN_SYMBOL}` file

See `COGNI-GIT-ADMIN-INTEGRATION.md` for integration details.

### Troubleshooting
```bash
# Check wallet balance
cast balance $(cast wallet address --private-key $WALLET_PRIVATE_KEY) --rpc-url $EVM_RPC_URL

# Test RPC connectivity  
cast block latest --rpc-url $EVM_RPC_URL
```

## Deploy.s.sol

Deploys CogniSignal with existing DAO.

```bash
make deploy-contract  # Deploy and verify
```

**Required:** `DAO_ADDRESS`, `WALLET_PRIVATE_KEY`, `ETHERSCAN_API_KEY`

**Production Deployment:**
- Sepolia: `0x8F26cF7b9ca6790385E255E8aB63acc35e7b9FB1` (Verified)
- DAO: `0xa38d03Ea38c45C1B6a37472d8Df78a47C1A31EB5`