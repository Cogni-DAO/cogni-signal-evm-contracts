# Aragon OSx Provider

Deploys Aragon OSx DAO with TokenVoting plugin.

## Files

**AragonOSxProvider.sol** - Implements IGovProvider using official Aragon imports

## Configuration

Receives addresses via `providerSpecificConfig`:
- DAOFactory address  
- PluginSetupProcessor address
- TokenVotingRepo address

Decodes and validates addresses have deployed code.

## Output

Returns `GovDeploymentResult`:
- `daoAddress`: Aragon DAO contract
- `votingPluginAddress`: TokenVoting plugin  
- `tokenAddress`: Governance token (created by plugin)
- `providerType`: "aragon-osx"

## Voting Settings

- **Mode**: EarlyExecution - executes when outcome mathematically certain
- **Support Threshold**: 50%  
- **Min Participation**: 50%
- **Min Duration**: 3600 seconds
- **Min Proposer Voting Power**: 1 token

Initial holder receives 1 governance token.

## Implementation

Uses official Aragon imports:
- `@aragon/osx/framework/dao/DAOFactory.sol`
- `token-voting-plugin/src/TokenVoting.sol`  
- `token-voting-plugin/src/base/MajorityVotingBase.sol`
- `token-voting-plugin/src/erc20/GovernanceERC20.sol`

Deployment via `DAOFactory.createDao()` with `InstalledPlugin[]` dynamic array return.

## ABI Compatibility

TokenVotingSetup requires 7 parameters (was 3, fixed):
1. VotingSettings  
2. TokenSettings
3. MintSettings
4. TargetConfig
5. minApprovals (uint256)
6. pluginMetadata (bytes)
7. excludedAccounts (address[])

Fixed 0x20 malformed address decoding by using official imports instead of custom interfaces.


## Error Handling

Uses `Address.functionCall()` to bubble exact revert data. Validates:
- Contract addresses have code
- PSP matches DAOFactory configuration
- Plugin installation returns valid addresses
- Governance token created successfully

## Sepolia Addresses

- DAOFactory: `0xB815791c233807D39b7430127975244B36C19C8e`
- PluginSetupProcessor: `0xC24188a73dc09aA7C721f96Ad8857B469C01dC9f`  
- TokenVotingRepo: `0x424F4cA6FA9c24C03f2396DF0E96057eD11CF7dF`
