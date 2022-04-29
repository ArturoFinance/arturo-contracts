// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IQuickswapLiquidity.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IERC20.sol';

contract QuickswapLiquidity is IQuickswapLiquidity{
    event LiquidityAddedTo(uint amountA, uint amountB, uint liquidity);

    address private constant ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    // address private constant MATIC = 0x0000000000000000000000000000000000001010;
    // address private constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    // address private constant PAIR =  0x1a2E7582a0d3c3474A2aBdd833B6E3748DF8a7fd;

    constructor() {}

    function addLiquidityToQuickswap(
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB
    ) external override {
        IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);
        IERC20(_tokenB).transferFrom(msg.sender, address(this), _amountB);

        IERC20(_tokenA).approve(ROUTER, _amountA);
        IERC20(_tokenB).approve(ROUTER, _amountB);

        (uint amountA, uint amountB, uint liquidity) = IUniswapV2Router02(ROUTER)
            .addLiquidity(
                _tokenA,
                _tokenB,
                _amountA,
                _amountB,
                1,
                1,
                address(this),
                block.timestamp
            );

        emit LiquidityAddedTo(amountA, amountB, liquidity);
    }
}
