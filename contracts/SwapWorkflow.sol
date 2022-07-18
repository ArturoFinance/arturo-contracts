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
    event TokensSwapApproved(address protocol, address token, uint256 amount);
    
    constructor() {
        interval = 5 minutes;
        lastExecuted = block.timestamp;
    }

    function approveSwapToProtocol(address _tokenIn, uint256 _amountIn) external {
        IERC20(_tokenIn).approve(ROUTER, _amountIn);

        emit TokensSwapApproved(ROUTER, _tokenIn, _amountIn);
    }

    function swap(
        address _owner,
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        uint _amountOutMin
    ) external override returns (uint[] memory amountOut) {
        IERC20(_tokenIn).transferFrom(_owner, address(this), _amountIn);

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

        amountOut = IUniswapV2Router02(ROUTER).swapExactTokensForTokens(
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
