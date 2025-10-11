# CogniSignal Event Integration Guide

For cogni-admin team to consume on-chain governance signals.

## Contract Details
- **Contract Address:** `0x8F26cF7b9ca6790385E255E8aB63acc35e7b9FB1`
- **Network:** Sepolia (Chain ID: 11155111)
- **Event Name:** `CogniAction`

## Event ABI
```solidity
event CogniAction(
    address indexed dao,
    uint256 indexed chainId,
    string repo,
    string action,
    string target,
    uint256 pr,
    bytes32 commit,
    bytes extra,
    address indexed executor
);
```

## Event Topic Hash
```
0xfd9a8ea95d56c7bd709823c6589c50386a2e5833892ef0e93c7bf63fee30bde1
```

## Off-chain Decoded Payload
What cogni-admin should expect after decoding:

```json
{
  "schema": "cogni.action@1",
  "dao": "0xa38d03Ea38c45C1B6a37472d8Df78a47C1A31EB5",
  "chainId": 11155111,
  "repo": "Cogni-DAO/cogni-git-review",
  "action": "PR_APPROVE",
  "target": "pull_request", 
  "pr": 112,
  "commit": "0x000000000000000000000000000000000000000000000000000000000000dead",
  "executor": "0xa38d03Ea38c45C1B6a37472d8Df78a47C1A31EB5",
  "nonce": 1,
  "deadline": 4102444800,
  "txHash": "0x...",
  "blockNumber": 123456,
  "logIndex": 0
}
```

## Extra Data Decoding
The `extra` field contains ABI-encoded data:
```solidity
(uint256 nonce, uint64 deadline, string paramsJson) = abi.decode(extra, (uint256, uint64, string));
```

## Supported Actions (v1)
- `PR_APPROVE` - Approve pull requests

## Webhook Setup
Monitor contract address `0x8F26cF7b9ca6790385E255E8aB63acc35e7b9FB1` on Sepolia for `CogniAction` events using your preferred method (Alchemy, QuickNode, etc.).