# Aragon OSx Provider

Deploys production-ready Aragon OSx DAO with Admin Plugin for mainnet/testnet use.

## Files

**AragonOSxProvider.sol** - Implements IGovProvider for Aragon OSx  
**AragonInterfaces.sol** - Official Aragon OSx contract interfaces and addresses

## Functionality

- Deploys ERC20 governance token
- Creates Aragon DAO via DAOFactory
- Installs Admin Plugin with CogniSignal execution permissions
- Returns standardized deployment addresses

## Network Support

- **Sepolia**: Full support with official contracts
- **Mainnet**: Available (not tested)

## Required Contracts

Uses official Aragon OSx deployments:
- DAOFactory
- PluginSetupProcessor  
- Admin Plugin Repository

## Integration Notes

- Validates contract addresses before deployment
- Handles plugin installation via PluginSetupProcessor
- Grants EXECUTE_PERMISSION to CogniSignal contract
- Admin plugin address returned for external integrations