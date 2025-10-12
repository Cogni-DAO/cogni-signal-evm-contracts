# Development Chain Setup

Complete development stack deployment: ERC20 Token → DAO → CogniSignal Contract.

## Quick Start

```bash
# 1. Set environment variables
export DEV_WALLET_PRIVATE_KEY=0x...    # Your funded Sepolia private key  
export RPC_URL=https://...             # Sepolia RPC URL

# 2. Deploy complete stack
forge script script/SetupDevChain.s.sol:SetupDevChain --rpc-url $RPC_URL --broadcast

# 3. Copy output environment variables to cogni-git-admin .env
```

## Prerequisites

### 1. Funded Sepolia Wallet

You need a wallet with **~0.05 ETH on Sepolia** for deployment costs.

#### Option A: Create New Wallet
```bash
# Generate new wallet
cast wallet new

# Fund the address with Sepolia ETH from:
# - https://sepoliafaucet.com/
# - https://faucets.chain.link/sepolia
# - https://faucet.quicknode.com/ethereum/sepolia
```

#### Option B: Use Existing Wallet  
```bash
# Export private key from MetaMask/wallet
# Fund address on Sepolia testnet
```

### 2. RPC Endpoint

Get a Sepolia RPC URL from:
- [Alchemy](https://dashboard.alchemy.com/) - `https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY`
- [Infura](https://infura.io/) - `https://sepolia.infura.io/v3/YOUR_PROJECT_ID`
- [QuickNode](https://quicknode.com/) - Custom endpoint

## Environment Variables

### Required
```bash
# Wallet Configuration
DEV_WALLET_PRIVATE_KEY=0x1234...    # Private key for funded Sepolia wallet
RPC_URL=https://eth-sepolia...      # Sepolia RPC endpoint
```

### Optional (with defaults)
```bash
TOKEN_NAME="Cogni Governance Token"    # ERC20 token name
TOKEN_SYMBOL="CGT"                     # ERC20 token symbol  
TOKEN_SUPPLY=1000000000000000000000000 # Initial supply (1M tokens)
```

## Script Output

The script deploys and outputs environment variables for cogni-git-admin:

```bash
🎉 DEPLOYMENT COMPLETE!
========================
ERC20 Token:     0x...
DAO:            0x...  
CogniSignal:    0x...
Chain ID:       11155111
Deployer:       0x...

📋 ENVIRONMENT VARIABLES FOR COGNI-GIT-ADMIN:
==============================================
COGNI_CHAIN_ID=11155111
COGNI_SIGNAL_CONTRACT=0x...
COGNI_ALLOWED_DAO=0x...
E2E_DAO_ADDRESS=0x...
E2E_GOVERNANCE_TOKEN=0x...
# ... (copy all to cogni-git-admin .env)
```

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ERC20 Token   │    │   Simple DAO    │    │  CogniSignal    │
│                 │    │                 │    │                 │
│ • 18 decimals   │◄───│ • Token-based   │◄───│ • DAO-only      │
│ • 1M supply     │    │ • Direct exec   │    │ • Event emitter │
│ • Mint to owner │    │ • Owner control │    │ • GitHub bridge │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Component Details

**ERC20 Token (`CogniToken`)**
- Standard OpenZeppelin ERC20 implementation
- 18 decimals, configurable initial supply
- All tokens minted to deployer for testing

**Simple DAO (`SimpleDAO`)**  
- Minimal DAO with `execute()` function matching IDAO interface
- Owner-controlled for development (deployer becomes owner)
- Compatible with cogni-git-admin E2E tests
- Token reference for future governance upgrades

**CogniSignal Contract**
- Existing production contract from `src/CogniSignal.sol`
- Restricted to DAO address via `onlyDAO` modifier
- Emits `CogniAction` events for GitHub operations

## Usage Examples

### Direct DAO Execution (Development)
```solidity
// SimpleDAO owner can execute directly
SimpleDAO.Action[] memory actions = new SimpleDAO.Action[](1);
actions[0] = SimpleDAO.Action({
    to: cogniSignalAddress,
    value: 0,
    data: abi.encodeWithSignature(
        "signal(string,string,string,uint256,bytes32,bytes)",
        "owner/repo", "PR_APPROVE", "pull_request", 123, 
        bytes32(0), extraData
    )
});

dao.execute(actions, 0); // Execute with no failure tolerance
```

### Environment Setup for E2E Tests
After deployment, the output provides all necessary environment variables for:
- cogni-git-admin integration tests
- Alchemy webhook configuration
- Development workflow testing

## Security Notes

⚠️ **Development Only**: This setup is for development/testing purposes:
- DAO owner is deployer address (not a multisig)
- Private keys are in environment variables
- Contracts are not verified (use `--verify` flag if needed)

For production, consider:
- Multisig DAO ownership
- Hardware wallet deployment
- Contract verification on Etherscan
- Governance token distribution

## Troubleshooting

### Deployment Fails
```bash
# Check wallet balance
cast balance $DEPLOYER_ADDRESS --rpc-url $RPC_URL

# Test RPC connectivity  
cast block latest --rpc-url $RPC_URL

# Verify private key format (must start with 0x)
echo $DEV_WALLET_PRIVATE_KEY
```

### Gas Estimation Errors
```bash
# Add gas limit and price
forge script script/SetupDevChain.s.sol:SetupDevChain \
  --rpc-url $RPC_URL --broadcast \
  --gas-limit 3000000 --gas-price 20000000000
```

### Contract Verification (Optional)
```bash
# Add Etherscan API key and verify flag
export ETHERSCAN_API_KEY=...
forge script script/SetupDevChain.s.sol:SetupDevChain \
  --rpc-url $RPC_URL --broadcast --verify
```