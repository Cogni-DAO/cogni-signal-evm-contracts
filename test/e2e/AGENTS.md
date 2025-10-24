# E2E Testing

Tests against real network state using forks.

## Basic Structure
```solidity
contract MyContractE2E is Test {
    address constant DAO = 0xa38d03Ea38c45C1B6a37472d8Df78a47C1A31EB5; // Real address
    MyContract public myContract;

    function setUp() public {
        vm.createSelectFork(vm.envString("EVM_RPC_URL"));
        myContract = new MyContract(DAO);
    }
}
```

## Test Real Workflows

### Direct DAO Call
```solidity
function test_DirectDAOCall() public {
    vm.prank(DAO);
    myContract.signal("github", "https://github.com/owner/repo", "merge", "change", "42", "");
}
```

### DAO Governance Execution
```solidity
function test_DAOGovernanceExecution() public {
    IDAO.Action[] memory actions = new IDAO.Action[](1);
    actions[0] = IDAO.Action({
        to: address(myContract),
        value: 0,
        data: abi.encodeWithSignature(
            "signal(string,string,string,string,string,bytes)",
            "github", "https://github.com/owner/repo", "merge", "change", "42",
            abi.encode(uint256(1), uint64(1234567890), string('{"merge_method":"merge"}'))
        )
    });

    vm.expectEmit(true, true, true, true, address(myContract));
    emit ExpectedEvent(args);

    vm.prank(DAO);
    IDAO(DAO).execute(actions, 0);
}
```

### Multi-VCS Test Examples
```solidity
// GitHub PR merge
signal("github", "https://github.com/owner/repo", "merge", "change", "42", extra);

// GitLab collaborator management  
signal("gitlab", "https://gitlab.com/owner/repo", "grant", "collaborator", "alice", extra);

// Future VCS providers
// signal("gerrit", "https://gerrit.company.com/owner/repo", "merge", "change", "123", extra);
```

## Key Rules

- **Use real addresses** - From environment variables, not hardcoded
- **Fork networks** - `vm.createSelectFork(vm.envString("RPC_URL"))`
- **Test complete workflows** - End-to-end user journeys
- **Validate full events** - Still use `vm.expectEmit(true, true, true, true)`