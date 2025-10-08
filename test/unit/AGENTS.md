# Unit Testing

Fast, isolated tests without external dependencies.

## Basic Structure
```solidity
contract MyContractTest is Test {
    MyContract public myContract;
    address public constant DAO = address(0x123);

    function setUp() public {
        myContract = new MyContract(DAO);
    }
}
```

## Test Categories

### Constructor
```solidity
function test_Constructor() public view {
    assertEq(myContract.DAO(), DAO);
}
```

### Access Control
```solidity
function test_OnlyDAO_Success() public {
    vm.prank(DAO);
    myContract.restrictedFunction();
}

function test_OnlyDAO_RevertWhen_NotDAO() public {
    vm.prank(address(0x456));
    vm.expectRevert("NOT_DAO");
    myContract.restrictedFunction();
}
```

### Events
```solidity
function test_EmitsEvent() public {
    vm.expectEmit(true, true, true, true, address(myContract));
    emit MyEvent(param1, param2);
    
    myContract.functionThatEmits(param1, param2);
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