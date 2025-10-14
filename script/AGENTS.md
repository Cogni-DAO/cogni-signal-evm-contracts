# Deployment Scripts

## SetupDevChain.s.sol

Complete development stack deployment with modular governance provider system.

### Architecture
Deploys a complete stack using pluggable governance providers:
1. **Governance Provider** - Modular system supporting multiple DAO frameworks
2. **ERC20 Token** - Governance token with configurable parameters
3. **DAO Contract** - Selected based on provider (Aragon OSx, SimpleDAO, etc.)
4. **CogniSignal** - Governance-agnostic signal aggregation contract

### Governance Provider System

The deployment uses a provider pattern (`script/gov_providers/`) that enables:
- **IGovProvider** - Standard interface for all governance providers
- **GovProviderFactory** - Factory with auto-selection and fallback logic
- **AragonOSxProvider** - Production-ready Aragon OSx with admin plugin support
- **SimpleDaoProvider** - Lightweight fallback for development environments

Provider selection logic:
1. `GOV_PROVIDER=aragon` (default) - Aragon OSx deployment
2. `GOV_PROVIDER=simple` - Forces SimpleDAO deployment

### Usage
```bash
# Set environment (add to .env file)
WALLET_PRIVATE_KEY=0x...
EVM_RPC_URL=https://eth-sepolia...
GOV_PROVIDER=aragon  # Optional: aragon|simple

# Deploy complete stack
make dao-setup
```

**Prerequisites:** Funded Sepolia wallet (~0.05 ETH) - Get from sepoliafaucet.com or faucets.chain.link/sepolia

### Environment Variables
**Required:**
- `WALLET_PRIVATE_KEY` - Funded wallet private key
- `EVM_RPC_URL` - Network RPC endpoint

**Optional:**
- `GOV_PROVIDER` - Governance provider selection (default: "aragon")
- `TOKEN_NAME` - Token name (default: "Cogni Governance Token")
- `TOKEN_SYMBOL` - Token symbol (default: "CGT")  
- `TOKEN_SUPPLY` - Initial supply (default: 1M tokens)

### Output

The deployment script provides an MVP .env.TOKEN output:

1. **Deployment Summary** - All deployed contract addresses
2. **Environment Variables** - Ready for copy/paste to cogni-git-admin
3. **Persistent Storage** - Saves to `.env.{TOKEN_SYMBOL}` file

#### Generated Variables for cogni-git-admin Integration

**Core Variables (Required):**
- `WALLET_PRIVATE_KEY` - Wallet used for deployment and execution
- `EVM_RPC_URL` - Network RPC endpoint
- `SIGNAL_CONTRACT` - CogniSignal contract address
- `DAO_ADDRESS` - DAO contract address for governance
- `CHAIN_ID` - Network chain ID

**Governance-Specific Variables:**
- `ARAGON_ADMIN_PLUGIN_CONTRACT` - Admin plugin (Aragon OSx deployments only)
- `GOVERNANCE_TOKEN` - ERC20 governance token address
- `GOV_PROVIDER_TYPE` - Provider type used ("aragon" or "simple")

#### Integration Workflow

1. Run `make dao-setup` to deploy stack
2. Copy console output variables or `.env.{TOKEN_SYMBOL}` file
3. Paste variables into the bottom of the cogni-git-admin `.env` file
4. Set up an Alchemy webhook, monitoring `SIGNAL_CONTRACT` and sending to cogni-git-admin `ALCHEMY_PROXY_URL` with `ALCHEMY_SIGNING_KEY`
5. `npm run e2e` testing with cogni-git-admin

**Note:** The system currently operates with single wallet execution for proof of concept testing. Production deployment requires proper multi-signature governance setup, and tests should involve dao voting. Not just an admin wallet triggering the CogniSignal.

### Troubleshooting
```bash
# Check wallet balance (get address from private key)
cast wallet address --private-key $WALLET_PRIVATE_KEY
cast balance $(cast wallet address --private-key $WALLET_PRIVATE_KEY) --rpc-url $EVM_RPC_URL

# Test RPC connectivity  
cast block latest --rpc-url $EVM_RPC_URL

# If deployment fails, check .env variables are loaded
make dao-setup  # Uses Makefile which auto-loads .env
```

**Note:** For governance provider integration best practices, see `script/gov_providers/AGENTS.md`.

---

## Deploy.s.sol

Foundry script for deploying CogniSignal contract with existing DAO.

### Usage
```bash
forge script script/Deploy.s.sol:Deploy --rpc-url $EVM_RPC_URL --broadcast --verify
```

### Environment Variables
- `DAO_ADDRESS` - Existing DAO address that will control the contract
- `WALLET_PRIVATE_KEY` - Deployer private key  
- `ETHERSCAN_API_KEY` - For contract verification

### Validations
- Ensures DAO address is not zero
- Ensures DAO address is not the deployer address
- Logs deployment details for verification

### Production Deployment Record
- **Sepolia**: `0x8F26cF7b9ca6790385E255E8aB63acc35e7b9FB1` ✅ Verified
- **DAO**: `0xa38d03Ea38c45C1B6a37472d8Df78a47C1A31EB5`