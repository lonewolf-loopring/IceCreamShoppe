// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/**
 * @title DexRouterProxy
 * @dev This is the PERMANENT address for your Router.
 * It points to the DexRouter logic and is managed by DexProxyAdmin.
 */
contract DexRouterProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic, _admin, _data) {}
}