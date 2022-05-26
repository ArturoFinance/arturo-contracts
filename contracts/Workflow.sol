// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract Workflow is KeeperCompatibleInterface {
    /**
    * Use an interval in seconds and a timestamp to slow execution of Upkeep
    */
    address private constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant WMATIC = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    address private constant ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;// deployed at Polygon mainnet and testnet

    address public creator;
    address public tokenA;
    address public tokenB;
    uint public tokenAmountA;
    uint public tokenAmountB;
    uint256 public immutable interval;
    uint256 public lastTimeStamp;
    bool public newWorkflowCreated;

    event TokensSwapped(address tokenIn, address tokenOut, address to);
    event LiquidityAddedTo(uint amountA, uint amountB, uint liquidity);
    event LiquidityRemoved(uint amountA, uint amountB);

    constructor() {
        interval = 5 minutes;
        lastTimeStamp = block.timestamp;
        newWorkflowCreated = false;
    }

    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB
    ) external {
        require(_tokenA != address(0), "Workflow: invalid token address");
        require(_tokenB != address(0), "Workflow: invalid token address");
        require(_amountA != 0, "Workflow: token amount should not be zero");
        require(_amountB != 0, "Workflow: token amount should not be zero");

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
                1,
                1,
                address(this),
                block.timestamp
            );
        emit LiquidityAddedTo(amountA, amountB, liquidity);
    }

    function removeLiquidity(address _tokenA, address _tokenB, address _pair) external {
        require(_tokenA != address(0), "Workflow: invalid token address");
        require(_tokenB != address(0), "Workflow: invalid token address");
        require(_pair != address(0), "Workflow: invalid pair address");

        uint liquidity = IERC20(_pair).balanceOf(address(this));
        require(liquidity != 0, "Workflow: has no balance");

        IERC20(_pair).approve(ROUTER, liquidity);

        (uint amountA, uint amountB) = IUniswapV2Router02(ROUTER).removeLiquidity(
            _tokenA,
            _tokenB,
            liquidity,
            1,
            1,
            msg.sender,
            block.timestamp
        );

        emit LiquidityRemoved(amountA, amountB);
    }

    function _swap(
        address from,
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        uint _amountOutMin
    ) internal {
        require(from != address(0), "Workflow: invalid address");
        require(_tokenIn != address(0), "Workflow: invalid token address");
        require(_tokenOut != address(0), "Workflow: invalid token address");
        require(_amountIn != 0, "Workflow: token amount should not be zero");

        IERC20(_tokenIn).transferFrom(from, address(this), _amountIn);
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
            from,
            block.timestamp
        );

        emit TokensSwapped(_tokenIn, _tokenOut, creator);
    }

    function create(
        address _tokenA,
        address _tokenB,
        uint _tokenAmountA,
        uint _tokenAmountB
    ) public {
        tokenA = _tokenA;
        tokenB = _tokenB;
        tokenAmountA = _tokenAmountA;
        tokenAmountB = _tokenAmountB;
        creator = msg.sender;
        newWorkflowCreated = true;
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool, bytes memory ) {
        if (
            block.timestamp > interval + lastTimeStamp  &&
            newWorkflowCreated
        ) {
            return(true, bytes(""));
        }

        return(false, bytes(""));
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        _swap(creator, tokenA, tokenB, tokenAmountA, 100000000);

        lastTimeStamp = block.timestamp;
    }
}
