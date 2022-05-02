// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapLiquidity {
    function addLiquidityToUniswap(
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB
    ) external;
}
