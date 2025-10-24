# CogniSignal EVM Contracts

Minimal on-chain governance signals for GitHub operations via [cogni-git-admin](https://github.com/Cogni-DAO/cogni-git-admin).

## Status: Proof of Concept Working ✅

End-to-end integration functioning with single wallet execution for testing. See `COGNI-GIT-ADMIN-INTEGRATION.md` for complete integration details.

## Setup Prerequisites

### 0. Install MetaMask
If you haven't already, install [MetaMask browser extension](https://metamask.io/).

### 1. Create Test Wallet
1. Open MetaMask and click "Create a new wallet"
2. Set wallet name: `<your test account>` (e.g., "Cogni Dev Wallet")  
3. Add Sepolia testnet:
   - Click network dropdown → "Add network"
   - **Network Name:** Sepolia test network
   - **RPC URL:** `https://sepolia.infura.io/v3/` (or use step 3 URL)
   - **Chain ID:** `11155111`
   - **Currency Symbol:** SepoliaETH
   - **Block Explorer:** `https://sepolia.etherscan.io`

### 2. Get Test ETH from Faucet
Fund your wallet with ~0.1 ETH from any Sepolia faucet:
- **Alchemy Faucet:** [sepoliafaucet.com](https://sepoliafaucet.com/)
- **Chainlink Faucet:** [faucets.chain.link/sepolia](https://faucets.chain.link/sepolia)
- **QuickNode Faucet:** [faucet.quicknode.com/ethereum/sepolia](https://faucet.quicknode.com/ethereum/sepolia)

💡 **Get Private Key:** In MetaMask → Account Details → "Show private key" → Enter password → Copy key

### 3. Get RPC URL
Choose one provider and sign up for a free API key:

**Alchemy (Recommended):**
1. Go to [dashboard.alchemy.com](https://dashboard.alchemy.com/)
2. Create account → "Create new app" 
3. Select "Ethereum" → "Sepolia"
4. Copy HTTP URL: `https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY`

**Infura:**
1. Go to [infura.io](https://infura.io/)  
2. Create project → Select "Web3 API"
3. Copy endpoint: `https://sepolia.infura.io/v3/YOUR_PROJECT_ID`

**QuickNode:**
1. Go to [quicknode.com](https://quicknode.com/)
2. Create endpoint → "Ethereum" → "Sepolia"
3. Copy HTTP Provider URL

### 4. Get Etherscan API Key (Required for Verification)
Contract verification ensures transparency and enables interaction through Etherscan:

1. Go to [etherscan.io/register](https://etherscan.io/register)
2. Create free account and verify email
3. Visit [etherscan.io/apidashboard](https://etherscan.io/apidashboard)
4. Click "Add" to create new API key
5. Copy the generated key: `YourApiKeyToken`

💡 **Free tier** provides 100,000 requests/day - sufficient for development use.

## Quick Start

```bash
# 1. Copy environment template
cp .env.TOKEN.example .env

# 2. Edit .env with your values:
# WALLET_PRIVATE_KEY=0x...    # From MetaMask account details  
# EVM_RPC_URL=https://eth-sepolia...  # From step 3 above
# ETHERSCAN_API_KEY=YourApiKeyToken   # From step 4 above

# 3. Deploy complete development stack with automatic verification
make dao-setup

# 4. Copy generated environment variables to cogni-git-admin
# The script outputs variables to console and saves to .env.{TOKEN_SYMBOL}
# These variables enable end-to-end testing with cogni-git-admin

# Run tests
forge test        
forge build       
```

### Troubleshooting Verification

**Common Issues:**
- **"Could not detect deployment"**: Wait 30 seconds for Etherscan indexing, then retry
- **"Pending in queue"**: Etherscan is processing - verification continues automatically
- **API rate limits**: Free tier provides 100k requests/day - sufficient for development

**Manual verification fallback:**
```bash
# If automatic verification fails, verify manually:
forge verify-contract CONTRACT_ADDRESS src/CogniSignal.sol:CogniSignal \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --chain sepolia \
  --constructor-args $(cast abi-encode "constructor(address)" $DAO_ADDRESS)
```

### Integration Output

The `make dao-setup` command generates environment variables for cogni-git-admin:
- Displays variables in console for easy copy/paste
- Saves to `.env.{TOKEN_SYMBOL}` file for reference
- Includes all addresses needed for E2E testing

## Contract Details

- **CogniSignal:** `0x7115D79246D1aE2D4bF5a6D5fA626B426fE8F5cD` ([Verified on Sepolia](https://sepolia.etherscan.io/address/0x7115d79246d1ae2d4bf5a6d5fa626b426fe8f5cd))
- **DAO:** `0xA382320be88f1c6856d3bcdeBa9Ce5C73A553cB6`
- **Action:** `PR_APPROVE` - Approve pull requests

## Documentation

- `AGENTS.md` - Project overview and architecture
- `COGNI-GIT-ADMIN-INTEGRATION.md` - Complete integration guide
- `script/AGENTS.md` - Deployment script details
