// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import '@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

contract UniswapLiquidity {
    enum ProtocolTypes {
        UniswapV2,
        UniswapV3
    }

    // routers
    address private constant UNISWAP_V2_ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address private constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;


    event LiquidityAdded(address protocol);
    event LiquidityAddApproved(address protocol, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(address protocol, uint256 amountA, uint256 amountB);
    event LiquidityRemoveApproved(address protocol, address pair, uint256 amount);

    function approveAddLiquidityToProtocol(
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB,
        ProtocolTypes pType
    ) external {
        if (pType == ProtocolTypes.UniswapV2) {
            IERC20(_tokenA).approve(UNISWAP_V2_ROUTER, _amountA);
            IERC20(_tokenB).approve(UNISWAP_V2_ROUTER, _amountB);
    
            emit LiquidityAddApproved(UNISWAP_V2_ROUTER, _amountA, _amountB);
        } else if (pType == ProtocolTypes.UniswapV3) {
            IERC20(_tokenA).approve(UNISWAP_V3_ROUTER, _amountA);
            IERC20(_tokenB).approve(UNISWAP_V3_ROUTER, _amountB);
    
            emit LiquidityAddApproved(UNISWAP_V2_ROUTER, _amountA, _amountB);
        }
    }

    function approveRemoveLiquidityFromProtocol(
        address _pair,
        ProtocolTypes pType
    ) external {
        uint liquidity = IERC20(_pair).balanceOf(address(this));
        require(liquidity != 0, "Workflow: has no balance");

        if (pType == ProtocolTypes.UniswapV2) {
            IERC20(_pair).approve(UNISWAP_V2_ROUTER, liquidity);

            emit LiquidityRemoveApproved(UNISWAP_V2_ROUTER, _pair, liquidity);
        } else if (pType == ProtocolTypes.UniswapV3) {
            IERC20(_pair).approve(UNISWAP_V3_ROUTER, liquidity);

            emit LiquidityRemoveApproved(UNISWAP_V3_ROUTER, _pair, liquidity);
        }
    }

    function addLiquidityToPool(
        address _owner,
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB,
        ProtocolTypes pType
    ) external {
        require(_tokenA != address(0), "Workflow: invalid token address");
        require(_tokenB != address(0), "Workflow: invalid token address");
        require(_amountA != 0, "Workflow: token amount should not be zero");
        require(_amountB != 0, "Workflow: token amount should not be zero");

        IERC20(_tokenA).transferFrom(_owner, address(this), _amountA);
        IERC20(_tokenB).transferFrom(_owner, address(this), _amountB);

        if (pType == ProtocolTypes.UniswapV2) {
            IUniswapV2Router02(UNISWAP_V2_ROUTER)
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

            emit LiquidityAdded(UNISWAP_V2_ROUTER);
        } else if (pType == ProtocolTypes.UniswapV3) {
            LiquidityManagement.AddLiquidityParams memory liquidityParams = LiquidityManagement.AddLiquidityParams({
                token0: _tokenA,
                token1: _tokenB,
                fee: 3000,
                recipient: _owner,
                tickLower: 1,
                tickUpper: 1,
                amount0Desired: _amountA,
                amount1Desired: _amountB,
                amount0Min: 1,
                amount1Min: 1
            });

            // (
            //     uint128 liquidity,
            //     uint256 amount0,
            //     uint256 amount1,
            //     IUniswapV3Pool pool
            // ) = LiquidityManagement.addLiquidity(liquidityParams);

            emit LiquidityAdded(UNISWAP_V3_ROUTER);
        }
    }

    function removeLiquidityFromPool(
        address _owner,
        address _tokenA,
        address _tokenB,
        address _pair,
        ProtocolTypes pType
    ) external {
        require(_tokenA != address(0), "Workflow: invalid token address");
        require(_tokenB != address(0), "Workflow: invalid token address");
        require(_pair != address(0), "Workflow: invalid pair address");

        uint liquidity = IERC20(_pair).balanceOf(address(this));
        require(liquidity != 0, "Workflow: has no balance");

        if (pType == ProtocolTypes.UniswapV2) {
            (uint amountA, uint amountB) = IUniswapV2Router02(UNISWAP_V2_ROUTER).removeLiquidity(
                _tokenA,
                _tokenB,
                liquidity,
                1,
                1,
                _owner,
                block.timestamp
            );

            emit LiquidityRemoved(UNISWAP_V2_ROUTER, amountA, amountB);
        } else if (pType == ProtocolTypes.UniswapV3) {
            (uint256 amountA, uint256 amountB) = IUniswapV3Pool(UNISWAP_V3_ROUTER).burn(1, 1, uint128(liquidity));

            emit LiquidityRemoved(UNISWAP_V3_ROUTER, amountA, amountB);
        }
    }
}