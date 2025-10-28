# Aragon OSx Provider

Deploys production-ready Aragon OSx DAO with Multisig plugin for secure multi-signature governance.

## Files

**AragonOSxProvider.sol** - Implements IGovProvider for Aragon OSx  
**AragonInterfaces.sol** - Official Aragon OSx contract interfaces and addresses

## Input Requirements

- **WALLET_PRIVATE_KEY**: Deployment wallet private key
- **EVM_RPC_URL**: Sepolia RPC endpoint
- **MULTISIG_INITIAL_MEMBER**: Initial multisig member wallet address
- **GOV_PROVIDER**: Set to "aragon-osx"

## Output

- **DAO_ADDRESS**: Main Aragon DAO contract
- **MULTISIG_PLUGIN_ADDRESS**: Multisig plugin contract
- **SIGNAL_CONTRACT**: CogniSignal contract address
- **CHAIN_ID**: Network chain ID (11155111 for Sepolia)

## Aragon Configuration

**Multisig Settings:**
- Initial threshold: 1 (single member initially)
- Min approvals: 1 (configurable via proposals)
- Only listed: true (restricts proposal creation to multisig members)
- Member management: Use `addAddresses(address[])` method via proposals

**Permissions:**
- EXECUTE_PERMISSION_ID granted to multisig plugin only
- UPDATE_MULTISIG_SETTINGS_PERMISSION_ID for member management
- No EOA or admin plugin holds execution rights
- Multisig proposal → approve → execute flow required

## Network Support

- **Sepolia**: Full support with official contracts
- Uses official Aragon OSx DAOFactory and Multisig plugin
- **Multisig Plugin Repository**: `0x9e7956C8758470dE159481e5DD0d08F8B59217A2`

## Integration Notes

- Proposal-based governance: All CogniSignal calls must be proposed and approved
- E2E flow: Create proposal → Approve (threshold met) → Execute approved actions
- Member management: Use proposals to call `addAddresses()` for expanding membership
- Deprecates AddressListVoting (which was deprecated by Aragon)

## How to Find Plugin Repository Address

```bash
npm install @aragon/multisig-plugin-artifacts
node -e "console.log(require('@aragon/multisig-plugin-artifacts').addresses.pluginRepo.sepolia)"
# Output: 0x9e7956C8758470dE159481e5DD0d08F8B59217A2
```