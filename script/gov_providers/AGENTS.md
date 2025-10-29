# Governance Providers

Modular system enabling CogniSignal to work with any DAO framework.

## Directory Structure

**IGovProvider.sol** - Standard interface with `GovConfig` struct containing `tokenInitialHolder`  
**GovProviderFactory.sol** - Provider selection and instantiation  
**Aragon/** - Aragon OSx with TokenVoting plugin  
**SimpleDao/** - SimpleDAO fallback

## Provider Selection

- **ARAGON**: Aragon OSx deployment  
- **SIMPLE**: SimpleDAO deployment

Configure via `GOV_PROVIDER` environment variable.

## Architecture

Providers implement `IGovProvider` interface:
1. Receive `GovConfig` with token parameters and addresses
2. Deploy framework-specific governance infrastructure  
3. Return `GovDeploymentResult` with DAO, plugin, and token addresses

## Integration Practices

**1. Address Validation**
```bash
cast code <CONTRACT_ADDRESS> --rpc-url <RPC>  # Verify contract exists
cast storage <CONTRACT> 0x360894...           # Check proxy implementation
```

**2. Function Selector Debugging**  
```bash
cast sig "functionName(type1,type2,...)"      # Generate expected selector
cast calldata "functionName(...)" args...     # Test encoding locally
```

**3. Use Official Artifacts**
- **DO**: `@org/project/artifacts/src/addresses.json`
- **DON'T**: Hardcode addresses or guess interfaces
- **Example**: Aragon DAO Factory vs DAORegistry are different contracts

**4. Plugin Data Encoding**
```bash
cast call <PLUGIN_REPO> "getVersion((uint8,uint16))" "(1,2)" --rpc-url <RPC>
curl https://dweb.link/ipfs/<CID>  # Fetch build metadata for _data ABI
```
**Critical**: Plugin `_data` structure comes from IPFS build metadata, not docs.

**5. Systematic Error Resolution**
1. Verify addresses with `cast code`
2. Confirm function selectors match exactly  
3. Check proxy delegation if "unrecognized selector"
4. Fetch official ABIs from build metadata
5. Test calldata encoding before on-chain calls

**6. Validation Checklist**
- [ ] Contract addresses have code
- [ ] Function selectors match (`cast sig`)
- [ ] Plugin repo exists in registry  
- [ ] Build metadata fetched and decoded
- [ ] Data encoding matches build ABI exactly
- [ ] Test deployment succeeds on testnet

**7. Common Pitfalls**
- Calling wrong contract (DAORegistry vs DAOFactory)
- Using stale/wrong network addresses
- Hand-rolling ABIs instead of official artifacts  
- Not following plugin build metadata ABI
- Missing contract existence validation

**8. Emergency Fallbacks**
- Keep working SimpleDAO fallback
- Try older plugin versions if latest fails
- Use `cast call` to test before script integration
- Manual encoding with cast/ethers offline

### Configuration

Addresses loaded from artifacts in SetupDevChain.s.sol, passed to providers via `providerSpecificConfig` bytes field. Providers decode their required addresses.