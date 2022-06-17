// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

contract SwapEngine {

    address private constant ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;// deployed at Polygon mainnet and testnet
    address private constant WMATIC = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    ISwapRouter public immutable swapRouterV3;

    enum SwapEngines {
        Apeswap,
        UniswapV2,
        UniswapV3,
        Paraswap,
        Oneinch
    }

    event TokensSwappedOnUniswapV2(address tokenIn, address tokenOut, address to);
    event TokensSwappedOnUniswapV3(address tokenIn, address tokenOut, address to);
    event TokensSwapApproved(address protocol, address token, uint256 amount);

    constructor(ISwapRouter _swapRouterV3) {
        swapRouterV3 = _swapRouterV3;
    }

    function swapOnProtocol(
        SwapEngines engine,
        address _owner,
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        uint _amountOutMin
    ) external {
        if (engine == SwapEngines.UniswapV2) {
            _swapOnUniswapV2(_owner, _tokenIn, _tokenOut, _amountIn, _amountOutMin);
        } else if (engine == SwapEngines.UniswapV3) {
            _swapOnUniswapV3(_owner, _tokenIn, _tokenOut, _amountIn);
        }
    }

    function approveSwapToProtocol(address _tokenIn, uint256 _amountIn) external {
        IERC20(_tokenIn).approve(ROUTER, _amountIn);

        emit TokensSwapApproved(ROUTER, _tokenIn, _amountIn);
    }

    function _swapOnUniswapV2(
        address _owner,
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        uint _amountOutMin
    ) internal {
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

        IUniswapV2Router02(ROUTER).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            _owner,
            block.timestamp
        );

        emit TokensSwappedOnUniswapV2(_tokenIn, _tokenOut, _owner);
    }

    function _swapOnUniswapV3(
        address _owner,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) internal returns (uint256 amountOut) {
        // msg.sender must approve this contract

        // Transfer the specified amount of _tokenIn to this contract.
        TransferHelper.safeTransferFrom(_tokenIn, _owner, address(this), _amountIn);

        // Approve the router to spend _tokenIn.
        TransferHelper.safeApprove(_tokenIn, address(swapRouterV3), _amountIn);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: 3000,
                recipient: _owner,
                deadline: block.timestamp,
                amountIn: _amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouterV3.exactInputSingle(params);
        emit TokensSwappedOnUniswapV3(_tokenIn, _tokenOut, _owner);
    }
}
