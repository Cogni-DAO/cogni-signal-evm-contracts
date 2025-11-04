// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract NonTransferableVotes is ERC20, ERC20Votes, Ownable {
    mapping(address => bool) public minters;

    constructor(string memory n, string memory s)
        ERC20(n, s)
        ERC20Permit(n)   // v4: name here
    {} 

    // block nonzero→nonzero transfers; allow mint (from=0) and burn (to=0)
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal override(ERC20) // v4: only ERC20 declares this hook
    {
        if (from != address(0) && to != address(0)) revert("Transfers disabled");
        super._beforeTokenTransfer(from, to, amount);
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == owner() || minters[msg.sender], "Not authorized");
        require(amount == 1e18, "Must mint exactly 1e18");           // fixed unit
        require(balanceOf(to) == 0, "Address already has 1");         // one-and-done
        _mint(to, 1e18);
        _delegate(to, to); // keep votes live
    }

    function grantMintRole(address account) external onlyOwner {
        minters[account] = true;
    }

    function revokeMintRole(address account) external onlyOwner {
        minters[account] = false;
    }

    // required OZ v4 overrides for ERC20Votes
    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal override(ERC20, ERC20Votes)
    { super._afterTokenTransfer(from, to, amount); }

    function _mint(address to, uint256 amount)
        internal override(ERC20, ERC20Votes)
    { super._mint(to, amount); }

    function _burn(address from, uint256 amount)
        internal override(ERC20, ERC20Votes)
    { super._burn(from, amount); }
}