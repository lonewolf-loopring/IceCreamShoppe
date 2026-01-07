// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/**
 * @title DexProxyAdmin
 * @dev This contract is the owner of the Router Proxy. 
 * It allows the 'Ice Cream Shoppe' wallet to upgrade the Router.
 */
contract DexProxyAdmin is ProxyAdmin {
    /**
     * @dev The constructor sets the initial owner of the Admin contract.
     * This should be your Ice Cream Shoppe wallet.
     */
    constructor(address initialOwner) ProxyAdmin(initialOwner) {}
}