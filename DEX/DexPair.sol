// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDexFactory {
    function feeTo() external view returns (address);
    function getSisterPair(address tokenA, address tokenB) external view returns (address);
}

/**
 * @title DexPair
 * @dev The Self-Aware engine for the ART Bridge.
 * Custom Names: ART-ETH-LP / ART-TAIKO-LP.
 */
contract DexPair is ERC20 {
    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           
    uint112 private reserve1;           

    string private _customName;
    string private _customSymbol;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Dex: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() ERC20("", "") {
        factory = msg.sender;
    }

    function initialize(
        address _token0, 
        address _token1, 
        string calldata name_, 
        string calldata symbol_
    ) external {
        require(msg.sender == factory, 'Dex: FORBIDDEN');
        token0 = _token0;
        token1 = _token1;
        _customName = name_;
        _customSymbol = symbol_;
    }

    function name() public view override returns (string memory) { return _customName; }
    function symbol() public view override returns (string memory) { return _customSymbol; }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    /**
     * @dev INTERNAL REBALANCE LOGIC
     * Manual absolute difference used to save gas and avoid library errors.
     */
    function _selfBalance() internal {
        address sister = IDexFactory(factory).getSisterPair(token0, token1);
        if (sister == address(0)) return;

        (uint112 sRes0, uint112 sRes1) = DexPair(sister).getReserves();
        if (sRes1 == 0 || reserve1 == 0) return; // Prevent division by zero
        
        uint currentRatio = (uint(reserve0) * 1e18) / reserve1;
        uint sisterRatio = (uint(sRes0) * 1e18) / sRes1;

        if (currentRatio != sisterRatio) {
            address feeTo = IDexFactory(factory).feeTo();
            if (feeTo != address(0)) {
                // Manual absolute difference calculation
                uint diff = currentRatio > sisterRatio ? currentRatio - sisterRatio : sisterRatio - currentRatio;
                uint surplus = diff / 1e12; 
                
                if (surplus > 0) _mint(feeTo, surplus);
            }
        }
    }

    function swap(uint amount0Out, uint amount1Out, address to) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'Dex: INSUFFICIENT_OUTPUT');
        
        // Transfer tokens out first
        if (amount0Out > 0) IERC20(token0).transfer(to, amount0Out);
        if (amount1Out > 0) IERC20(token1).transfer(to, amount1Out);

        // Update reserves based on actual balance remaining
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)));
        
        // Capture the revenue from tension
        _selfBalance();
    }

    function _update(uint balance0, uint balance1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'Dex: OVERFLOW');
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
    }
}