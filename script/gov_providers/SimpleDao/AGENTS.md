# SimpleDAO Provider

Lightweight fallback provider. Untested and likely non-functional.

## Files

**SimpleDaoProvider.sol** - Basic DAO implementation

## Output

Returns `GovDeploymentResult`:
- `daoAddress`: SimpleDAO contract
- `votingPluginAddress`: address(0) - SimpleDAO doesn't have voting plugin
- `tokenAddress`: CogniToken governance token
- `providerType`: "simple-dao"