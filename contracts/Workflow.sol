// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Workflow is KeeperCompatibleInterface {
    AggregatorV3Interface public tokenAPriceFeed;
    AggregatorV3Interface public tokenBPriceFeed;

    // Protocols
    address private constant WMATIC =
        0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    address private constant QUICKSWAP_ROUTER =
        0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // deployed at Polygon mainnet and testnet

    // Events
    event TokensSwapApproved(address protocol, address token, uint256 amount);
    event TokensSwapped(address tokenIn, address tokenOut, address to);
    event LiquidityAddedTo(uint256 amountA, uint256 amountB, uint256 liquidity);
    event PriceDataUpdated(int256, int256);
    event WorkflowCreated(uint256 workflowId, address indexed owner);

    uint256 public immutable interval;

    struct LimitOrderWorkflowDetail {
        address tokenA;
        address tokenB;
        uint256 tokenAReferencePrice; // Token price when User created the worklow
        uint256 stopLossThresholdRate;
        uint256 stopLossSwapAmount;
        uint256 takeProfitThresholdRate;
        uint256 takeProfitSwapAmount;
        bool isPaused;
    }

    struct LimitOrderWorkflow {
        uint256 workflowId;
        address owner;
        LimitOrderWorkflowDetail details;
    }

    LimitOrderWorkflow[] limitOrderWorkflows;

    uint256 currentWorkflowId;
    uint256 lastTimeStamp;

    // list of tokens to watch prices at each check upkeep round
    address[] tokenToWatchPrices;

    //We will need to store token price references also to check token references
    mapping(address => uint256) tokenLatestPriceReference;

    constructor() {
        interval = 300; //5min
        lastTimeStamp = block.timestamp;
    }

    function createLimitOrderWorkflow(LimitOrderWorkflowDetail calldata details)
        external
    {
        currentWorkflowId += 1;
        address owner = msg.sender;

        limitOrderWorkflows.push(
            LimitOrderWorkflow({
                workflowId: currentWorkflowId + 1,
                owner: owner,
                details: details
            })
        );

        emit WorkflowCreated(currentWorkflowId + 1, owner);
    }

    function fetchLatestPrices() internal {
        for (uint256 i; i < tokenToWatchPrices.length; i++) {
            address token = tokenToWatchPrices[i];

            AggregatorV3Interface tokenPriceFeed = AggregatorV3Interface(token);

            uint256 lastTokenPrice = uint256(
                getLatestTokenPrice(tokenAPriceFeed)
            );

            tokenLatestPriceReference[token] = lastTokenPrice;

            // TODO: Do the lookup here
        }
    }

    function lookupLimitOrderWorkflows() private {
        for (uint256 i; i < limitOrderWorkflows.length; i++) {
            LimitOrderWorkflowDetail memory details = limitOrderWorkflows[i]
                .details;

            address tokenA = details.tokenA;

            uint256 priceRef = details.tokenAReferencePrice;

            // check if tokenPrice < or > to latest price
            /*
        priceRef < tokenLatestPriceReference[tokenA] ? 
            checkStopLoss(LimitOrderWorkflows[i], tokenLatestPriceReference[tokenA]) :
            checkTakeProfit(LimitOrderWorkflows[i], tokenLatestPriceReference[tokenA]);
        */

            if (priceRef < tokenLatestPriceReference[details.tokenA]) {
                _checkStopLoss(
                    limitOrderWorkflows[i],
                    tokenLatestPriceReference[details.tokenA]
                );
            }
        }
    }

    function _checkStopLoss(
        LimitOrderWorkflow memory limitWorkflow,
        uint256 tokenLatestPrice
    ) private {
        LimitOrderWorkflowDetail memory details = limitWorkflow.details;
        uint256 delta = details.tokenAReferencePrice - tokenLatestPrice;
        uint256 stopLossRate = details.stopLossThresholdRate;
        uint256 deltaRate = uint256(delta) / 100;

        if (deltaRate >= stopLossRate) {
            _swap(
                details.tokenA,
                details.tokenB,
                details.stopLossSwapAmount,
                1,
                limitWorkflow.owner
            );
        }
    }

    function _swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address owner
    ) public {
        // IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        IERC20(_tokenIn).transferFrom(owner, address(this), _amountIn);

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

        IUniswapV2Router02(QUICKSWAP_ROUTER).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            owner,
            block.timestamp + 3600 * 24
        );

        emit TokensSwapped(_tokenIn, _tokenOut, msg.sender);
    }

    function approveSwapToProtocol(address _tokenIn, uint256 _amountIn)
        external
    {
        IERC20(_tokenIn).approve(address(this), _amountIn);
        IERC20(_tokenIn).approve(QUICKSWAP_ROUTER, _amountIn);
        emit TokensSwapApproved(QUICKSWAP_ROUTER, _tokenIn, _amountIn);
    }

    /**
     * Get the latest ETH and BTC prices
     */
    function getLatestTokenPrice(AggregatorV3Interface tokenPriceFeed)
        public
        view
        returns (int256)
    {
        (
            ,
            /*uint80 roundID*/
            int256 price,
            ,
            ,

        ) = /*uint startedAt*/
            /*uint timeStamp*/
            /*uint80 answeredInRound*/
            tokenPriceFeed.latestRoundData();
        return price;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        //Revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;

            fetchLatestPrices();
        }
    }
}
