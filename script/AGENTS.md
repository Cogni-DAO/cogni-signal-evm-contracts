# Deployment Scripts

## SetupDevChain.s.sol ⭐ **New**

Complete development stack deployment: ERC20 Token → DAO → CogniSignal.

### Usage
```bash
# Set environment
export DEV_WALLET_PRIVATE_KEY=0x...
export RPC_URL=https://eth-sepolia...

# Deploy complete stack
forge script script/SetupDevChain.s.sol:SetupDevChain --rpc-url $RPC_URL --broadcast
```

### What It Deploys
1. **ERC20 Token** (`CogniToken`) - Governance token with configurable supply
2. **Simple DAO** (`SimpleDAO`) - Minimal DAO with execute() function
3. **CogniSignal** - Uses existing `Deploy.s.sol` script for consistency

### Environment Variables
**Required:**
- `DEV_WALLET_PRIVATE_KEY` - Funded Sepolia wallet private key
- `RPC_URL` - Sepolia RPC endpoint

**Optional:**
- `TOKEN_NAME` - Token name (default: "Cogni Governance Token")
- `TOKEN_SYMBOL` - Token symbol (default: "CGT")  
- `TOKEN_SUPPLY` - Initial supply (default: 1M tokens)

### Output
Prints copyable environment variables for `cogni-git-admin` .env configuration.

See `DEV-CHAIN-SETUP.md` for complete setup guide.

---

## Deploy.s.sol

Foundry script for deploying CogniSignal contract with existing DAO.

### Usage
```bash
forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --broadcast --verify
```

### Environment Variables
- `DAO_ADDRESS` - Existing DAO address that will control the contract
- `DEV_WALLET_PRIVATE_KEY` - Deployer private key  
- `ETHERSCAN_API_KEY` - For contract verification

### Validations
- Ensures DAO address is not zero
- Ensures DAO address is not the deployer address
- Logs deployment details for verification

### Production Deployment Record
- **Sepolia**: `0x8F26cF7b9ca6790385E255E8aB63acc35e7b9FB1` ✅ Verified
- **DAO**: `0xa38d03Ea38c45C1B6a37472d8Df78a47C1A31EB5`