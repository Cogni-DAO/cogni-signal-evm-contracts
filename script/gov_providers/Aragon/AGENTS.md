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
- `tokenAddress`: Custom NonTransferableVotes token (deployed first, ownership transferred to DAO)
- `providerType`: "aragon-osx"

## Voting Settings

- **Mode**: EarlyExecution - executes when outcome mathematically certain
- **Support Threshold**: 50%  
- **Min Participation**: 50%
- **Min Duration**: 3600 seconds
- **Min Proposer Voting Power**: 1 token

Initial holder receives 1 NonTransferableVotes token.

## Implementation

**Custom Token Deployment:**
1. Deploy NonTransferableVotes with deployer as temporary owner
2. Mint initial supply to configured holder
3. Create DAO using custom token address in TokenSettings
4. Transfer token ownership to DAO

Uses official Aragon imports plus custom token:
- `@aragon/osx/framework/dao/DAOFactory.sol`
- `token-voting-plugin/src/TokenVoting.sol`
- `token-voting-plugin/src/erc20/GovernanceERC20.sol` (for MintSettings structure)
- `../../../src/NonTransferableVotes.sol`

Deployment via `DAOFactory.createDao()` with empty `GovernanceERC20.MintSettings` to prevent plugin-side minting.

## ABI Compatibility

TokenVotingSetup requires 7 parameters:
1. VotingSettings  
2. TokenSettings
3. MintSettings
4. TargetConfig
5. minApprovals (uint256)
6. pluginMetadata (bytes)
7. excludedAccounts (address[])

Official imports provide proper ABI compatibility for address decoding.


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
