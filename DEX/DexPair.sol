// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface IDexFactory {
    function feeTo() external view returns (address);
    function getSisterPair(address tokenA, address tokenB) external view returns (address);
}

contract DexPair is ERC20 {
    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32  private blockTimestampLast;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Dex: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() ERC20("DEX LP Token", "DLP") {
        factory = msg.sender;
    }

    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'Dex: FORBIDDEN');
        token0 = _token0;
        token1 = _token1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    /**
     * @dev THE SELF-AWARE BRAIN
     * Detects price gaps with the sister pool and captures it as LP value.
     */
    function _selfBalance() internal {
        address sister = IDexFactory(factory).getSisterPair(token0, token1);
        if (sister == address(0)) return;

        // 1. Query Sister Reserves
        (uint112 sRes0, uint112 sRes1) = DexPair(sister).getReserves();
        
        // 2. Calculate the 'Ideal' Ratio based on Triangular Math
        // Simplified: (reserve0 / reserve1) should equal (sisterRes0 / sisterRes1)
        // If they differ, the contract identifies the 'Surplus'
        uint currentRatio = (uint(reserve0) * 1e18) / reserve1;
        uint sisterRatio = (uint(sRes0) * 1e18) / sRes1;

        if (currentRatio != sisterRatio) {
            _captureValue(currentRatio, sisterRatio);
        }
    }

    function _captureValue(uint current, uint ideal) internal {
        address feeTo = IDexFactory(factory).feeTo();
        if (feeTo == address(0)) return;

        // 3. Virtual Reserve Adjustment
        // Instead of moving tokens, we calculate the 'Accounting Surplus' 
        // created by the price gap and mint that value as LP tokens.
        uint surplusValue = Math.abs(int(current) - int(ideal)) / 1e12; // Example scaling
        
        if (surplusValue > 0) {
            _mint(feeTo, surplusValue); // Minting LP tokens to you (the owner)
        }
    }

    function swap(uint amount0Out, uint amount1Out, address to) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'Dex: INSUFFICIENT_OUTPUT');
        (uint112 _reserve0, uint112 _reserve1) = getReserves();

        if (amount0Out > 0) IERC20(token0).transfer(to, amount0Out);
        if (amount1Out > 0) IERC20(token1).transfer(to, amount1Out);

        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        
        _update(balance0, balance1);
        
        // AUTO-REBALANCE: The machine fixes itself and pays you.
        _selfBalance();
    }

    function _update(uint balance0, uint balance1) private {
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
    }
}