// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ISwapWorkflow.sol";

contract SwapWorkflow is ISwapWorkflow {
    address private constant ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;// deployed at Polygon mainnet and testnet
    address private constant WMATIC = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    uint256 public interval;
    uint256 public override lastExecuted;

    event TokensSwapped(address tokenIn, address tokenOut, address to);
    
    constructor() {
        interval = 5 minutes;
        lastExecuted = block.timestamp;
    }

    function swap(
        address _owner,
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        uint _amountOutMin
    ) external override {
        IERC20(_tokenIn).transferFrom(_owner, address(this), _amountIn);
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
            _owner,
            block.timestamp
        );

        lastExecuted = block.timestamp;
        emit TokensSwapped(_tokenIn, _tokenOut, _owner);
    }
}
