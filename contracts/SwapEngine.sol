// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import "hardhat/console.sol";

interface IApeRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface ISushiRouer {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IAggregationExecutor {
    /// @notice Make calls on `msgSender` with specified data
    function callBytes(address msgSender, bytes calldata data) external payable;  // 0x2636f7f8
}

interface IOneinchRouter {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    function swap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata data
    )
        external
        payable
        returns (
            uint256 returnAmount,
            uint256 spentAmount,
            uint256 gasLeft
        );

    function unoswap(
        IERC20 srcToken,
        uint256 amount,
        uint256 minReturn,
        bytes32[] calldata pools
    ) external returns (uint256 returnAmount);
}

interface IFireBirdRouter {
    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract SwapEngine {
    address private constant APESWAP_ROUTER = 0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607;
    address private constant UNISWAP_V2_ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address private constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address private constant SUSHISWAP_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address private constant ONEINCH_ROUTER = address(0);
    address private constant FIREBIRD_ROUTER = address(0);
    address private constant WMATIC = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;

    enum SwapEngines {
        Apeswap,
        UniswapV2,
        UniswapV3,
        Sushiswap,
        Oneinch,
        Firebird
    }

    event TokensSwappedOnUniswapV2(address tokenIn, address tokenOut, address to);
    event TokensSwappedOnUniswapV3(address tokenIn, address tokenOut, address to);
    event TokensSwappedOnApeswap(address tokenIn, address tokenOut, address to);
    event TokensSwappedOnSushiswap(address tokenIn, address tokenOut, address to);
    event TokenSwappedOnFirebird(address tokenIn, address tokenOut, address to);
    event UnowappedOnOneinch(address tokenIn, bytes32[] pool, uint256 amountOut);
    event AggregationSwappedOnOneinch(address tokenIn, address tokenOut, uint256 amountOut);

    event TokensApprovedOnUniswapV2(address protocol, address token, uint256 amount);
    event TokensApprovedOnUniswapV3(address protocol, address token, uint256 amount);
    event TokensApprovedOnApeswap(address protocol, address token, uint256 amount);
    event TokensApprovedOnSushiswap(address protocol, address token, uint256 amount);
    event TokensApprovedOnOneinch(address protocol, address token, uint256 amount);
    event TokensApprovedOnFirebird(address protocol, address token, uint256 amount);

    constructor() {}

    function approveSwapOnEngines(address _tokenIn, uint256 _amountIn, SwapEngines engineType) external {
        if (engineType == SwapEngines.UniswapV2) {
            IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);

            emit TokensApprovedOnUniswapV2(UNISWAP_V2_ROUTER, _tokenIn, _amountIn);
        } else if (engineType == SwapEngines.UniswapV3) {
            IERC20(_tokenIn).approve(UNISWAP_V3_ROUTER, _amountIn);

            emit TokensApprovedOnUniswapV3(UNISWAP_V3_ROUTER, _tokenIn, _amountIn);
        } else if (engineType == SwapEngines.Apeswap) {
            IERC20(_tokenIn).approve(APESWAP_ROUTER, _amountIn);

            emit TokensApprovedOnApeswap(APESWAP_ROUTER, _tokenIn, _amountIn);
        } else if (engineType == SwapEngines.Sushiswap) {
            IERC20(_tokenIn).approve(SUSHISWAP_ROUTER, _amountIn);

            emit TokensApprovedOnSushiswap(SUSHISWAP_ROUTER, _tokenIn, _amountIn);
        } else if (engineType == SwapEngines.Oneinch) {
            IERC20(_tokenIn).approve(ONEINCH_ROUTER, _amountIn);
        } else if (engineType == SwapEngines.Firebird) {
            IERC20(_tokenIn).approve(FIREBIRD_ROUTER, _amountIn);
        }
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
    ) external returns (uint amountOut) {
        require(engineType == SwapEngines.UniswapV2, "Unknown swap function");
        IERC20(_tokenIn).transferFrom(_owner, address(this), _amountIn);

        // address[] memory path = _getPath(_tokenIn, _tokenOut);

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

        amountOut = IUniswapV2Router02(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
            _amountIn,
            100000,
            path,
            _owner,
            block.timestamp
        )[0];

        emit TokensSwappedOnUniswapV2(_tokenIn, _tokenOut, _owner);
    }

    function swapOnUniswapV3(
        address _owner,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        SwapEngines engineType
    ) external returns (uint256 amountOut) {
        require(engineType == SwapEngines.UniswapV3, "Unknown swap function");
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
        require(engineType == SwapEngines.Apeswap, "Unknown swap function");

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

    function swapOnSushiswap(
        address _owner,
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        SwapEngines engineType
    ) external {
        require(engineType == SwapEngines.Sushiswap, "Unknown swap function");

        IERC20(_tokenIn).transferFrom(_owner, address(this), _amountIn);

        address[] memory path = _getPath(_tokenIn, _tokenOut);

        ISushiRouer(SUSHISWAP_ROUTER).swapExactTokensForTokens(
            _amountIn,
            1,
            path,
            _owner,
            block.timestamp
        );

        emit TokensSwappedOnSushiswap(_tokenIn, _tokenOut, _owner);
    }

    function swapOnFirebird(
        address _owner,
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        SwapEngines engineType
    ) external {
        require(engineType == SwapEngines.Firebird, "Unknow swap functions");

        IERC20(_tokenIn).transferFrom(_owner, address(this), _amountIn);

        address [] memory path = _getPath(_tokenIn, _tokenOut);

        IFireBirdRouter(FIREBIRD_ROUTER).swapExactTokensForTokens(
            _tokenIn,
            _tokenOut,
            _amountIn,
            1,
            path,
            _owner,
            block.timestamp
        );

        emit TokenSwappedOnFirebird(_tokenIn, _tokenOut, _owner);
    }

    function unoswapOnOneinch(
        address _owner,
        address _tokenIn,
        uint _amountIn,
        bytes32[] calldata _pools,
        SwapEngines engineType
    ) external {
        require(engineType == SwapEngines.Oneinch, "Unknown swap function");
        IERC20(_tokenIn).transferFrom(_owner, address(this), _amountIn);

        uint256 amountOut = IOneinchRouter(ONEINCH_ROUTER).unoswap(
            IERC20(_tokenIn),
            _amountIn,
            1,
            _pools
        );

        emit UnowappedOnOneinch(_tokenIn, _pools, amountOut);
    }

    function aggregationswapOnOneinch(
        address _owner,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        SwapEngines engineType
    ) external {
        require(engineType == SwapEngines.Oneinch, "Unknown swap function");
        IERC20(_tokenIn).transferFrom(_owner, address(this), _amountIn);

        (uint256 amountOut, , ) = IOneinchRouter(ONEINCH_ROUTER).swap(
            IAggregationExecutor(address(this)),
            IOneinchRouter.SwapDescription(
                IERC20(_tokenIn),
                IERC20(_tokenOut),
                payable(_owner),
                payable(_owner),
                _amountIn,
                1,
                1,
                bytes('')
            ),
            bytes('')
        );

        emit AggregationSwappedOnOneinch(_tokenIn, _tokenOut, amountOut);
    }

}
