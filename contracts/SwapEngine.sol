// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

interface IApeRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract SwapEngine {
    address private constant APESWAP_ROUTER = 0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607;
    address private constant UNISWAP_V2_ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address private constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address private constant ONEINCH_V3_ROUTER = 0x11111112542D85B3EF69AE05771c2dCCff4fAa26;
    address private constant WMATIC = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;

    enum SwapEngines {
        Apeswap,
        UniswapV2,
        UniswapV3,
        Paraswap,
        Oneinch
    }

    event TokensSwappedOnUniswapV2(address tokenIn, address tokenOut, address to);
    event TokensSwappedOnUniswapV3(address tokenIn, address tokenOut, address to);
    event TokensSwappedOnApeswap(address tokenIn, address tokenOut, address to);

    event TokensApprovedOnUniswapV2(address protocol, address token, uint256 amount);
    event TokensApprovedOnUniswapV3(address protocol, address token, uint256 amount);
    event TokensApprovedOnApeswap(address protocol, address token, uint256 amount);

    constructor() {}

    function approveSwapOnUniswapV2(address _tokenIn, uint256 _amountIn) external {
        IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);

        emit TokensApprovedOnUniswapV2(UNISWAP_V2_ROUTER, _tokenIn, _amountIn);
    }

    function approveSwapOnUniswapV3(address _tokenIn, uint256 _amountIn) external {
        IERC20(_tokenIn).approve(UNISWAP_V3_ROUTER, _amountIn);

        emit TokensApprovedOnUniswapV3(UNISWAP_V3_ROUTER, _tokenIn, _amountIn);
    }

    function approveSwapOnApeswap(address _tokenIn, uint256 _amountIn) external {
        IERC20(_tokenIn).approve(APESWAP_ROUTER, _amountIn);

        emit TokensApprovedOnApeswap(APESWAP_ROUTER, _tokenIn, _amountIn);
    }

    function _getPath(address _tokenIn, address _tokenOut) internal pure returns (address[] memory) {
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

        return path;
    }

    function swapOnUniswapV2(
        address _owner,
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        SwapEngines engineType
    ) external {
        require(engineType == SwapEngines.UniswapV2, "Please call a reasonable function");

        IERC20(_tokenIn).transferFrom(_owner, address(this), _amountIn);

        address[] memory path = _getPath(_tokenIn, _tokenOut);

        IUniswapV2Router02(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
            _amountIn,
            1,
            path,
            _owner,
            block.timestamp
        );

        emit TokensSwappedOnUniswapV2(_tokenIn, _tokenOut, _owner);
    }

    function swapOnUniswapV3(
        address _owner,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        SwapEngines engineType
    ) external returns (uint256 amountOut) {
        require(engineType == SwapEngines.UniswapV3, "Please call a reasonable function");
        // Transfer the specified amount of _tokenIn to this contract.
        TransferHelper.safeTransferFrom(_tokenIn, _owner, address(this), _amountIn);
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
        amountOut = ISwapRouter(UNISWAP_V3_ROUTER).exactInputSingle(params);
        emit TokensSwappedOnUniswapV3(_tokenIn, _tokenOut, _owner);
    }

    function swapOnApeswap(
        address _owner,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        SwapEngines engineType
    ) external {
        require(engineType == SwapEngines.UniswapV3, "Please call a reasonable function");

        IERC20(_tokenIn).transferFrom(_owner, address(this), _amountIn);
        address[] memory path = _getPath(_tokenIn, _tokenOut);

        IApeRouter(APESWAP_ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            1,
            path,
            _owner,
            block.timestamp    
        );

        emit TokensSwappedOnApeswap(_tokenIn, _tokenOut, _owner);
    }

}
