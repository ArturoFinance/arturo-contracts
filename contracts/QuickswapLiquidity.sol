// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IQuickswapLiquidity.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract QuickswapLiquidity is IQuickswapLiquidity {
    event TokensSwapped(address tokenIn, address tokenOut, address to);
    event LiquidityAddedTo(uint amountA, uint amountB, uint liquidity);

    address private constant ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;// deployed at Polygon mainnet and testnet
    address private constant WMATIC = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;

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
                10000000,
                10000000,
                msg.sender,
                block.timestamp + 3600 * 24
            );

        emit LiquidityAddedTo(amountA, amountB, liquidity);
    }

    function swap(
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        uint _amountOutMin
    ) external override {
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        IERC20(_tokenIn).approve(ROUTER, _amountIn);

        address[] memory path;
        if (_tokenIn == WMATIC || _tokenOut == WMATIC) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WMATIC;
            path[2] = _tokenOut;
        }

        IUniswapV2Router02(ROUTER).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            msg.sender,
            block.timestamp + 3600 * 24
        );

        emit TokensSwapped(_tokenIn, _tokenOut, msg.sender);
    }
}
