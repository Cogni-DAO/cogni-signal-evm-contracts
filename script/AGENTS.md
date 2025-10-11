# Deployment Scripts

## Deploy.s.sol

Foundry script for deploying CogniSignal contract.

### Usage
```bash
forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --broadcast --verify
```

### Environment Variables
- `DAO_ADDRESS` - DAO address that will control the contract
- `PRIVATE_KEY` - Deployer private key  
- `ETHERSCAN_API_KEY` - For contract verification

### Validations
- Ensures DAO address is not zero
- Ensures DAO address is not the deployer address
- Logs deployment details for verification

### Deployment Record
- **Sepolia**: `0x8F26cF7b9ca6790385E255E8aB63acc35e7b9FB1` ✅ Verified
- **DAO**: `0xa38d03Ea38c45C1B6a37472d8Df78a47C1A31EB5`