// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISwapWorkflow {
    // enum SwapType {
    //     Uniswap,
    //     Quickswap
    // }

    // function createSwapWorkflow(
    //     SwapType swapType,
    //     address tokenToSell,
    //     address tokenToBuy,
    //     uint256 sellAmount,
    //     uint256 buyAmount,
    //     uint256 maxSlippage
    // ) external;
    function lastExecuted() external view returns (uint256);

    function swap(
        address _owner,
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        uint _amountOutMin
    ) external;

}
