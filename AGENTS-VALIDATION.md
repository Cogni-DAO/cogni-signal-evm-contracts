# AGENTS-VALIDATION.md

How to validate Solidity contracts before deployment.

## Environment Setup
```bash
# Required in .env
RPC_URL=https://eth-sepolia.g.alchemy.com/v2/...
DAO_ADDRESS=0x...
PRIVATE_KEY=0x...
```

## Validation Commands

```bash
# 1. Build and test
forge build
forge test

# 2. Dry run deployment 
forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL

# 3. Deploy and validate on testnet
forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --broadcast
```

## Manual Testing with Anvil

```bash
# Start local fork
anvil --fork-url $RPC_URL --chain-id 31337

# Deploy to local fork
forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast

# Test contract calls
cast send 0x[CONTRACT] "signal(...)" ... --private-key 0x[KEY] --rpc-url http://localhost:8545
```

## Key Test Patterns

### Access Control
```solidity
function test_OnlyDAO_Success() public {
    vm.prank(DAO);
    signal.restrictedFunction();
}

function test_OnlyDAO_RevertWhen_NotDAO() public {
    vm.prank(address(0x123));
    vm.expectRevert("NOT_DAO");
    signal.restrictedFunction();
}
```

### Events
```solidity
vm.expectEmit(true, true, true, true, address(signal));
emit CogniAction(dao, chainId, repo, action, target, pr, commit, 
    abi.encode(uint256(1), uint64(1234567890), string('{"schema":"cogni.action@1"}')), executor);
signal.functionThatEmits();
```

### Access Control
```solidity
vm.prank(address(0x456));
vm.expectRevert("NOT_DAO");
signal.signal(repo, action, target, pr, commit, extra);
```

That's it. Keep tests simple and focused.