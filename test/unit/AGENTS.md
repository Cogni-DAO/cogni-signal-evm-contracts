# Unit Testing

Fast, isolated tests without external dependencies.

## Basic Structure
```solidity
contract CogniSignalTest is Test {
    CogniSignal public signal;
    address public constant DAO = address(0x123);

    event CogniAction(
        address indexed dao,
        uint256 indexed chainId,
        string  vcs,
        string  repoUrl,
        string  action,
        string  target,
        string  resource,
        bytes   extra,
        address indexed executor
    );

    function setUp() public {
        signal = new CogniSignal(DAO);
    }
}
```

## Test Categories

### Constructor
```solidity
function test_Constructor() public view {
    assertEq(signal.DAO(), DAO);
}
```

### Access Control
```solidity
function test_Signal_Success() public {
    vm.prank(DAO);
    signal.signal("github", "https://github.com/owner/repo", "merge", "change", "42", "");
}

function test_Signal_RevertWhen_NotDAO() public {
    vm.prank(address(0x456));
    vm.expectRevert("NOT_DAO");
    signal.signal("vcs", "repo", "action", "target", "resource", "");
}
```

### Events
```solidity
function test_Signal_EventFields() public {
    string memory vcs = "gitlab";
    string memory repoUrl = "https://gitlab.com/Cogni-DAO/test-repo";
    string memory action = "grant";
    string memory target = "collaborator";
    string memory resource = "alice";
    bytes memory extra = abi.encode(1, block.timestamp + 1 hours, '{"permission": "admin"}');

    vm.expectEmit(true, true, true, true, address(signal));
    emit CogniAction(DAO, block.chainid, vcs, repoUrl, action, target, resource, extra, DAO);
    
    vm.prank(DAO);
    signal.signal(vcs, repoUrl, action, target, resource, extra);
}
```

### Multi-VCS Test Patterns
```solidity
function test_MultipleActions() public {
    vm.startPrank(DAO);
    
    // GitHub PR merge
    signal.signal("github", "https://github.com/owner/repo1", "merge", "change", "1", "");
    // GitLab collaborator grant
    signal.signal("gitlab", "https://gitlab.com/owner/repo2", "grant", "collaborator", "alice", "");
    
    vm.stopPrank();
}
```

### Error Cases
```solidity
function test_RevertWhen_InvalidInput() public {
    vm.expectRevert("INVALID_INPUT");
    myContract.functionWithValidation(invalidInput);
}
```

## Key Rules

- **No forks** - Unit tests are local only
- **Test one thing** - Don't combine unrelated functionality  
- **Always validate events** - Use `vm.expectEmit(true, true, true, true)`
- **Test both success and failure** - Every access control needs both cases

## FaucetMinter.t.sol

22 unit tests covering token faucet functionality with mock contracts.

### Test Categories

**Constructor Tests:**
- Valid deployment with proper state initialization
- Revert on zero amount per claim
- Revert on invalid global cap (< amount per claim)

**Claim Tests:**
- Successful first claim with event emission and state updates
- Revert on duplicate claim from same address (`AlreadyClaimed`)
- Revert when faucet is paused (`FaucetPaused`)
- Revert when global cap would be exceeded (`GlobalCapExceeded`)
- Multiple different users can claim successfully

**Access Control Tests:**
- DAO can pause/unpause faucet
- DAO can update global cap configuration
- Non-DAO addresses cannot access restricted functions

**Reentrancy Protection:**
- Claim function properly protected with `ReentrancyGuard`
- Simulated reentrancy attacks are blocked

**View Function Tests:**
- `hasClaimed()` tracking works correctly
- `remainingTokens()` calculates available tokens under cap
- Permission ID constants match expected values

### Mock Contracts
- `MockDAO`: Simulates Aragon DAO permission system for faucet authorization
- `MockToken`: Simulates NonTransferableVotes with `grantMintRole()` and fixed 1e18 minting