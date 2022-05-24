// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract Workflow is KeeperCompatibleInterface {
    AggregatorV3Interface internal maticPriceFeed;
    AggregatorV3Interface internal daiPriceFeed;

    /**
    * Use an interval in seconds and a timestamp to slow execution of Upkeep
    */
    address private constant WMATIC = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    address private constant ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;// deployed at Polygon mainnet and testnet

    address public creator;
    address public tokenA;
    address public tokenB;
    uint public amountTokenA;
    uint public amountTokenB;
    uint256 public immutable interval;
    uint256 public lastTimeStamp;
    bool public newWorkflowCreated;

    event TokensSwapped(address tokenIn, address tokenOut, address to);
    event LiquidityAddedTo(uint amountA, uint amountB, uint liquidity);


    event PriceDataUpdated(int, int);

    /**
     * Network: Mumbai Testnet
     * ETH/USD 0x0715A7794a1dc8e42615F059dD6e406A6594651A
     * BTC/USD 0x007A22900a3B98143368Bd5906f8E17e9867581b
     */

    constructor() {
        interval = 5 minutes;
        lastTimeStamp = block.timestamp;
        maticPriceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
        daiPriceFeed = AggregatorV3Interface(0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046);
        newWorkflowCreated = false;
    }

    function _swap(
        address from,
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        uint _amountOutMin
    ) public {
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
        uint _amountTokenA,
        uint _amountTokenB
    ) public {
        tokenA = _tokenA;
        tokenB = _tokenB;
        amountTokenA = _amountTokenA;
        amountTokenB = _amountTokenB;
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
        _swap(creator, tokenA, tokenB, amountTokenA, 100000000);

        lastTimeStamp = block.timestamp;
    }
}
