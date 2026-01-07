// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

// Note: No "Ownable" or "AccessControl" imported here. 
// This makes the contract "Stateless" regarding permissions.
contract ArtToken is ERC20, ERC20Burnable {

    uint256 private constant TOTAL_SUPPLY = 100_000_000;
    
    constructor() ERC20("Art Token", "ART") {
        // Mints total supply to you once, then the 'printing press' is destroyed.
        _mint(msg.sender, TOTAL_SUPPLY * 10**decimals());
    }
}