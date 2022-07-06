// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract LiquidityProvide {
    address private constant WMATIC = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    address private constant UNISWAP_V2_ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    event LiquidityAdded(uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityAddApproved(address protocol, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(uint256 amountA, uint256 amountB);
    event LiquidityRemoveApproved(address protocol, address pair, uint256 amount);

    function approveAddLiquidityToProtocol(
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB
    ) external { 
        IERC20(_tokenA).approve(UNISWAP_V2_ROUTER, _amountA);
        IERC20(_tokenB).approve(UNISWAP_V2_ROUTER, _amountB);

        emit LiquidityAddApproved(UNISWAP_V2_ROUTER, _amountA, _amountB);
    }

    function approveRemoveLiquidityToProtocol(address _pair) external {
        uint liquidity = IERC20(_pair).balanceOf(address(this));
        require(liquidity != 0, "Workflow: has no balance");

        IERC20(_pair).approve(UNISWAP_V2_ROUTER, liquidity);

        emit LiquidityRemoveApproved(UNISWAP_V2_ROUTER, _pair, liquidity);
    }

    function addLiquidity(
        address _owner,
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB
    ) external {
        require(_tokenA != address(0), "Workflow: invalid token address");
        require(_tokenB != address(0), "Workflow: invalid token address");
        require(_amountA != 0, "Workflow: token amount should not be zero");
        require(_amountB != 0, "Workflow: token amount should not be zero");

        IERC20(_tokenA).transferFrom(_owner, address(this), _amountA);
        IERC20(_tokenB).transferFrom(_owner, address(this), _amountB);

        (uint amountA, uint amountB, uint liquidity) = IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .addLiquidity(
                _tokenA,
                _tokenB,
                _amountA,
                _amountB,
                1,
                1,
                _owner,
	            block.timestamp
            );

        emit LiquidityAdded(amountA, amountB, liquidity);
    }

    function removeLiquidity(
        address _owner,
        address _tokenA,
        address _tokenB,
        address _pair
    ) external {
        require(_tokenA != address(0), "Workflow: invalid token address");
        require(_tokenB != address(0), "Workflow: invalid token address");
        require(_pair != address(0), "Workflow: invalid pair address");

        uint liquidity = IERC20(_pair).balanceOf(address(this));
        require(liquidity != 0, "Workflow: has no balance");

        (uint amountA, uint amountB) = IUniswapV2Router02(UNISWAP_V2_ROUTER).removeLiquidity(
            _tokenA,
            _tokenB,
            liquidity,
            1,
            1,
            _owner,
            block.timestamp
        );

        emit LiquidityRemoved(amountA, amountB);
    }
}   