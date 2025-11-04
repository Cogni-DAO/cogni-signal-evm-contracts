// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {DaoAuthorizable} from "@aragon/osx-commons-contracts/src/permission/auth/DaoAuthorizable.sol";
import {IDAO} from "@aragon/osx-commons-contracts/src/dao/IDAO.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMint { 
    function mint(address to, uint256 amount) external; 
}

/**
 * @title FaucetMinter
 * @dev Token faucet for one-time token claims with DAO-controlled pause functionality
 * @notice Mints governance tokens to users who haven't claimed before
 */
contract FaucetMinter is ReentrancyGuard, DaoAuthorizable {
    /// @notice The governance token (for reads)
    IERC20 public immutable token;
    /// @notice The token minter interface
    IMint private immutable minter;
    
    /// @notice Permission ID constants
    bytes32 public constant PAUSE_PERMISSION_ID = keccak256("PAUSE_PERMISSION");
    bytes32 public constant CONFIG_PERMISSION_ID = keccak256("CONFIG_PERMISSION");
    
    /// @notice Amount of tokens to mint per claim (fixed at 1e18)
    uint256 public constant ONE = 1e18;
    uint256 public amountPerClaim;
    
    /// @notice Maximum total tokens that can ever be minted by this faucet
    uint256 public globalCap;
    
    /// @notice Total tokens minted by this faucet
    uint256 public totalMinted;
    
    /// @notice Whether the faucet is paused
    bool public paused;
    
    /// @notice Tracks addresses that have already claimed
    mapping(address => bool) public claimed;
    
    /// @notice Emitted when tokens are claimed
    event Claimed(address indexed claimer, uint256 amount);
    
    /// @notice Emitted when the faucet is paused/unpaused
    event PauseToggled(bool paused);
    
    /// @notice Emitted when amount per claim is updated
    event AmountPerClaimUpdated(uint256 oldAmount, uint256 newAmount);
    
    /// @notice Emitted when global cap is updated
    event GlobalCapUpdated(uint256 oldCap, uint256 newCap);
    
    /// @notice Custom errors for better revert messages
    error AlreadyClaimed(address claimer);
    error FaucetPaused();
    error GlobalCapExceeded(uint256 requested, uint256 available);
    error ZeroAmount();
    error InvalidCap(uint256 cap);
    
    /**
     * @param _dao The DAO address that will control this faucet
     * @param _token The governance token contract to mint from
     * @param _amountPerClaim Initial amount to mint per claim
     * @param _globalCap Maximum total tokens this faucet can ever mint
     */
    constructor(
        address _dao,
        address _token, 
        uint256 _amountPerClaim,
        uint256 _globalCap
    ) DaoAuthorizable(IDAO(_dao)) {
        if (_amountPerClaim != ONE) revert ZeroAmount();
        if (_globalCap < _amountPerClaim) revert InvalidCap(_globalCap);
        
        token = IERC20(_token);
        minter = IMint(_token);
        amountPerClaim = _amountPerClaim;
        globalCap = _globalCap;
        paused = false;
    }
    
    /**
     * @notice Claim tokens (one time per address)
     * @dev Requires MINT_PERMISSION_ID to be granted to this contract by the DAO
     */
    function claim() external nonReentrant {
        if (paused) revert FaucetPaused();
        if (claimed[msg.sender]) revert AlreadyClaimed(msg.sender);
        if (totalMinted + amountPerClaim > globalCap) {
            revert GlobalCapExceeded(amountPerClaim, globalCap - totalMinted);
        }
        
        claimed[msg.sender] = true;
        totalMinted += amountPerClaim;
        
        minter.mint(msg.sender, ONE); // token enforces 1e18 anyway
        
        emit Claimed(msg.sender, amountPerClaim);
    }
    
    /**
     * @notice Pause or unpause the faucet
     * @param _paused Whether to pause the faucet
     * @dev Only callable by the DAO
     */
    function pause(bool _paused) external auth(PAUSE_PERMISSION_ID) {
        paused = _paused;
        emit PauseToggled(_paused);
    }
    
    // removed: amountPerClaim is fixed at 1e18 to align with token invariant
    
    /**
     * @notice Update the global cap
     * @param _newCap New global cap (must be >= current total minted)
     * @dev Only callable by the DAO
     */
    function setGlobalCap(uint256 _newCap) external auth(CONFIG_PERMISSION_ID) {
        if (_newCap < totalMinted) revert InvalidCap(_newCap);
        
        uint256 oldCap = globalCap;
        globalCap = _newCap;
        
        emit GlobalCapUpdated(oldCap, _newCap);
    }
    
    /**
     * @notice Check if an address has claimed tokens
     * @param claimer Address to check
     * @return Whether the address has already claimed
     */
    function hasClaimed(address claimer) external view returns (bool) {
        return claimed[claimer];
    }
    
    /**
     * @notice Get remaining tokens that can be minted
     * @return Available tokens under the global cap
     */
    function remainingTokens() external view returns (uint256) {
        return globalCap - totalMinted;
    }
}