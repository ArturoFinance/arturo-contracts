// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Workflow is KeeperCompatibleInterface {

    AggregatorV3Interface public tokenAPriceFeed;
    AggregatorV3Interface public tokenBPriceFeed;  
    /**
    * Use an interval in seconds and a timestamp to slow execution of Upkeep
    */
    address private constant WMATIC = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    address private constant ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;// deployed at Polygon mainnet and testnet

    address private tokenA;
    address private tokenB;
    uint256 private amountTokenA;
    uint256 private amountTokenB;
    uint256 public immutable interval;
    uint256 public lastTimeStamp;
    int public lastTokenAPrice;
    int public prevTokenAPrice;
    int public lastTokenBPrice;
    int public prevTokenBPrice;
    bool public newWorkflowCreated;

    // Workflow related DS
    struct Workflow {
        uint256 workflowId;
        string name; // to store later to a dedicated backend for gas saving
        Action action;
        //Actions[] action; // A workflow can be complex
        uint256 frequency;
        bool isPaused;
    }

    struct Action {
        address protocol;
        Pair pair;
        ActionType action;
        Trigger trigger;
    }

    enum ActionType {
        Swap,
        Addliquidity
    }

    struct Pair {
        address tokenA;
        address TokenB;
        uint256 AmountA;
        uint256 AmountB;
    }

    struct Trigger{
        uint256 tokenRefPrice;
        EventTriggerType eventTriggerType;
        TriggerType triggerType;
        Metric metric;
    }

    enum EventTriggerType {
        TokenPriceInc,
        TokenPriceDownDec
    }

    enum TriggerType {
        Percentage, // when token price increase by X % from 
        ApproxAmountValue
    }
    

    struct Metric {
        EventTriggerType triggerType;
        uint value;
    }

    // Workflow related DS

    event TokensSwapped(address tokenIn, address tokenOut, address to);
    event LiquidityAddedTo(uint amountA, uint amountB, uint liquidity);


    event PriceDataUpdated(int, int);

    /**
     * Network: Mumbai Testnet
     * ETH/USD 0x0715A7794a1dc8e42615F059dD6e406A6594651A
     * BTC/USD 0x007A22900a3B98143368Bd5906f8E17e9867581b
     */

    constructor() {
        interval = 300; //5min
        lastTimeStamp = block.timestamp;
    }

    
    function _addLiquidityToQuickswap(
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB
    ) public {
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
                10000000,
                10000000,
                msg.sender,
                block.timestamp + 3600 * 24
            );

        emit LiquidityAddedTo(amountA, amountB, liquidity);
    }

    function _swap(
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        uint _amountOutMin
    ) public {
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
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
            msg.sender,
            block.timestamp + 3600 * 24
        );

        emit TokensSwapped(_tokenIn, _tokenOut, msg.sender);
    }

    function create(
        address _tokenA,
        address _tokenB,
        uint256 _amountTokenA,
        uint256 _amountTokenB
    ) public {
        tokenA = _tokenA;
        tokenB = _tokenB;
        amountTokenA = _amountTokenA;
        amountTokenB = _amountTokenB;
        tokenAPriceFeed = AggregatorV3Interface(_tokenA);
        tokenBPriceFeed = AggregatorV3Interface(_tokenB);
        lastTokenAPrice = getLatestTokenPrice(tokenAPriceFeed);
        lastTokenBPrice = getLatestTokenPrice(tokenBPriceFeed);
        newWorkflowCreated = true;
    }

     /**
     * Get the latest ETH and BTC prices
     */
    function getLatestTokenPrice(AggregatorV3Interface tokenPriceFeed) public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = tokenPriceFeed.latestRoundData();
        return price;
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

     function dispatchAction(Action  action) private {

    }

    function performUpkeep(bytes calldata /* performData */) external override {
        //Revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - lastTimeStamp) > interval && newWorkflowCreated) {
            lastTimeStamp = block.timestamp;
            prevTokenAPrice = lastTokenAPrice;
            prevTokenBPrice = lastTokenBPrice;
            lastTokenAPrice = getLatestTokenPrice(tokenAPriceFeed);
            lastTokenBPrice = getLatestTokenPrice(tokenBPriceFeed);

            if ((lastTokenAPrice - prevTokenAPrice) > prevTokenAPrice / 100)
                _swap(tokenA, tokenB, amountTokenA, 1);
            if ((prevTokenBPrice - lastTokenBPrice) > prevTokenBPrice / 100)
                _addLiquidityToQuickswap(tokenA, tokenB, amountTokenA, amountTokenB);
        }
    }
}