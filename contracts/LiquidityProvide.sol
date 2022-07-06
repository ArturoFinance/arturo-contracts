// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IApeRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

contract LiquidityProvide {
    enum ProtocolTypes {
        Apeswap,
        UniswapV2
    }

    address private constant WMATIC = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    address private constant APESWAP_ROUTER = 0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607;
    address private constant UNISWAP_V2_ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    event LiquidityAdded(address protocol, uint256 amountA, uint256 amountB, uint256 liquidity);
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
        } else if (pType == ProtocolTypes.Apeswap) {
            IERC20(_tokenA).approve(APESWAP_ROUTER, _amountA);
            IERC20(_tokenB).approve(APESWAP_ROUTER, _amountB);
    
            emit LiquidityAddApproved(APESWAP_ROUTER, _amountA, _amountB);
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
        } else if (pType == ProtocolTypes.Apeswap) {
            IERC20(_pair).approve(APESWAP_ROUTER, liquidity);

            emit LiquidityRemoveApproved(APESWAP_ROUTER, _pair, liquidity);
        }
    }

    function addLiquidityToUniswap(
        address _owner,
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB,
        ProtocolTypes pType
    ) external {
        require(pType == ProtocolTypes.UniswapV2, "Unknown protocol type");
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
                address(this),
	            block.timestamp
            );

        emit LiquidityAdded(UNISWAP_V2_ROUTER, amountA, amountB, liquidity);
    }

    function removeLiquidityFromUniswap(
        address _owner,
        address _tokenA,
        address _tokenB,
        address _pair,
        ProtocolTypes pType
    ) external {
        require(pType == ProtocolTypes.UniswapV2, "Unknown protocol type");
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

        emit LiquidityRemoved(UNISWAP_V2_ROUTER, amountA, amountB);
    }

    function addLiquidityToApeswap(
        address _owner,
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB,
        ProtocolTypes pType
    ) external {
        require(pType == ProtocolTypes.Apeswap, "Unknown protocol type");
        require(_tokenA != address(0), "Workflow: invalid token address");
        require(_tokenB != address(0), "Workflow: invalid token address");
        require(_amountA != 0, "Workflow: token amount should not be zero");
        require(_amountB != 0, "Workflow: token amount should not be zero");

        IERC20(_tokenA).transferFrom(_owner, address(this), _amountA);
        IERC20(_tokenB).transferFrom(_owner, address(this), _amountB);

        (uint amountA, uint amountB, uint liquidity) = IApeRouter(APESWAP_ROUTER)
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

        emit LiquidityAdded(APESWAP_ROUTER, amountA, amountB, liquidity);
    }

    function removeLiquidityFromApeswap(
        address _owner,
        address _tokenA,
        address _tokenB,
        address _pair,
        ProtocolTypes pType
    ) external {
        require(pType == ProtocolTypes.Apeswap, "Unknown protocol type");
        require(_tokenA != address(0), "Workflow: invalid token address");
        require(_tokenB != address(0), "Workflow: invalid token address");
        require(_pair != address(0), "Workflow: invalid pair address");

        uint liquidity = IERC20(_pair).balanceOf(address(this));
        require(liquidity != 0, "Workflow: has no balance");

        (uint amountA, uint amountB) = IApeRouter(APESWAP_ROUTER).removeLiquidity(
            _tokenA,
            _tokenB,
            liquidity,
            1,
            1,
            _owner,
            block.timestamp
        );

        emit LiquidityRemoved(APESWAP_ROUTER, amountA, amountB);
    }
}   