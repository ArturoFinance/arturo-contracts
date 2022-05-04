// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IQuickswapLiquidity {
    function addLiquidityToQuickswap(
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB
    ) external;

    function swap(
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        uint _amountOutMin
    ) external;
}
