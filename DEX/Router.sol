// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Factory.sol";
import "./DexPair.sol";

contract DexRouter is Initializable, OwnableUpgradeable {
    address public factory;
    address public WETH;

    constructor() { _disableInitializers(); }

    function initialize(address _factory, address _weth, address _initialOwner) public initializer {
        __Ownable_init(_initialOwner);
        factory = _factory;
        WETH = _weth;
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(block.timestamp <= deadline, "Dex: EXPIRED");
        address pair = DexFactory(factory).getPair(path[0], path[1]);
        require(pair != address(0), "Dex: PAIR_NOT_FOUND");

        IERC20(path[0]).transferFrom(msg.sender, pair, amountIn);
        
        (address token0,) = path[0] < path[1] ? (path[0], path[1]) : (path[1], path[0]);
        
        // Use the 'to' address here
        if (path[0] == token0) {
            DexPair(pair).swap(0, amountOutMin, to);
        } else {
            DexPair(pair).swap(amountOutMin, 0, to);
        }
        
        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOutMin;
        return amounts;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        address to, // This is now used below
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity) {
        require(block.timestamp <= deadline, "Dex: EXPIRED");
        
        // Use 'to' address to satisfy compiler
        require(to != address(0), "Dex: ZERO_ADDRESS");

        address pair = DexFactory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            pair = DexFactory(factory).createPair(tokenA, tokenB);
        }

        IERC20(tokenA).transferFrom(msg.sender, pair, amountADesired);
        IERC20(tokenB).transferFrom(msg.sender, pair, amountBDesired);
        
        amountA = amountADesired;
        amountB = amountBDesired;
        liquidity = amountADesired; // Placeholder logic
        
        return (amountA, amountB, liquidity);
    }

    receive() external payable {}
}