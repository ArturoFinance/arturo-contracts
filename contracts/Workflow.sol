// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Workflow is KeeperCompatibleInterface {
    address private constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant WMATIC = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    address private constant QUICKSWAP_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;// deployed at Polygon mainnet and testnet

    struct AddLiquidityWorkflowDetail {
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
    }

    struct AddLiquidityWorkflow {
        uint256 workflowId;
        address owner;
        AddLiquidityWorkflowDetail details;
    }

    struct RemoveLiquidityWorkflowDetail {
        address tokenA;
        address tokenB;
        address pair;
    }

    struct RemoveLiquidityWorkflow {
        uint256 workflowId;
        address owner;
        RemoveLiquidityWorkflowDetail details;
    }

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
    AddLiquidityWorkflow[] addLiquidityWorkflows;
    RemoveLiquidityWorkflow[] removeLiquidityWorkflows;
    // list of tokens to watch prices at each check upkeep round
    address[] public tokenToWatchPrices;

    //We will need to store token price references also to check token references
    mapping(address => uint256) tokenLatestPriceReference;

    AggregatorV3Interface public tokenAPriceFeed;
    AggregatorV3Interface public tokenBPriceFeed;

    uint256 public immutable interval;
    uint256 public lastTimeStamp;
    uint256 public currentWorkflowId;

    event LiquidityAdded(uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityAddApproved(address protocol, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(uint256 amountA, uint256 amountB);
    event LiquidityRemoveApproved(address protocol, address pair, uint256 amount);
    event TokensSwapped(address tokenIn, address tokenOut, address to);
    event TokensSwapApproved(address protocol, address token, uint256 amount);
    event PriceDataUpdated(int256, int256);
    event LimitOrderWorkflowCreated(uint256 workflowId, address indexed owner);
    event AddLiquidityWorkflowCreated(uint256 workflowId, address indexed owner);
    event RemoveLiquidityWorkflowCreated(uint256 workflowId, address indexed owner);

    constructor() {
        interval = 5 minutes;
        lastTimeStamp = block.timestamp;
    }

    function generateWorkflowId() public returns (uint256) {
        currentWorkflowId += 1;
        return currentWorkflowId;
    }

    function createLimitOrderWorkflow(LimitOrderWorkflowDetail calldata details) external {
        address owner = msg.sender;
        uint256 workflowId = generateWorkflowId();

        limitOrderWorkflows.push(
            LimitOrderWorkflow({
                workflowId: workflowId,
                owner: owner,
                details: details
            })
        );

        emit LimitOrderWorkflowCreated(workflowId, owner);
    }

    function createAddLiquidityWorkflow(AddLiquidityWorkflowDetail calldata details) external {
        uint256 workflowId = generateWorkflowId();
        address owner = msg.sender;

        addLiquidityWorkflows.push(
            AddLiquidityWorkflow({
                workflowId: workflowId,
                owner: owner,
                details: details
            })
        );

        emit AddLiquidityWorkflowCreated(workflowId, owner);
    }

    function createRemoveLiquidityWorkflow(RemoveLiquidityWorkflowDetail calldata details) external {
        uint256 workflowId = generateWorkflowId();
        address owner = msg.sender;

        removeLiquidityWorkflows.push(
            RemoveLiquidityWorkflow({
                workflowId: workflowId,
                owner: owner,
                details: details
            })
        );

        emit RemoveLiquidityWorkflowCreated(workflowId, owner);
    }

    function _fetchLatestPrices() internal {
        for (uint256 i; i < tokenToWatchPrices.length; i++) {
            address token = tokenToWatchPrices[i];

            AggregatorV3Interface tokenPriceFeed = AggregatorV3Interface(token);

            uint256 lastTokenPrice = uint256(
                getLatestTokenPrice(tokenPriceFeed)
            );

            tokenLatestPriceReference[token] = lastTokenPrice;

            // TODO: Do the lookup here
        }
    }

    function getLatestTokenPrice(AggregatorV3Interface tokenPriceFeed)
        public
        view
        returns (int256)
    {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/
            ,
            ,

        ) = /*uint timeStamp*/
            /*uint80 answeredInRound*/
            tokenPriceFeed.latestRoundData();
        return price;
    }

    function lookupLimitOrderWorkflows() private {
        for (uint256 i; i < limitOrderWorkflows.length; i++) {
            LimitOrderWorkflowDetail memory details = limitOrderWorkflows[i]
                .details;

            // address tokenA = details.tokenA;

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

    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB
    ) public {
        require(_tokenA != address(0), "Workflow: invalid token address");
        require(_tokenB != address(0), "Workflow: invalid token address");
        require(_amountA != 0, "Workflow: token amount should not be zero");
        require(_amountB != 0, "Workflow: token amount should not be zero");

        IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);
        IERC20(_tokenB).transferFrom(msg.sender, address(this), _amountB);

        (uint amountA, uint amountB, uint liquidity) = IUniswapV2Router02(QUICKSWAP_ROUTER)
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

        emit LiquidityAdded(amountA, amountB, liquidity);
    }

    function removeLiquidity(address _tokenA, address _tokenB, address _pair) public {
        require(_tokenA != address(0), "Workflow: invalid token address");
        require(_tokenB != address(0), "Workflow: invalid token address");
        require(_pair != address(0), "Workflow: invalid pair address");

        uint liquidity = IERC20(_pair).balanceOf(address(this));
        require(liquidity != 0, "Workflow: has no balance");

        (uint amountA, uint amountB) = IUniswapV2Router02(QUICKSWAP_ROUTER).removeLiquidity(
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

    function approveAddLiquidityToProtocol(
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB
    ) external {
        IERC20(_tokenA).approve(address(this), _amountA);
        IERC20(_tokenB).approve(address(this), _amountB);
        
        IERC20(_tokenA).approve(QUICKSWAP_ROUTER, _amountA);
        IERC20(_tokenB).approve(QUICKSWAP_ROUTER, _amountB);

        emit LiquidityAddApproved(QUICKSWAP_ROUTER, _amountA, _amountB);
    }

    function approveRemoveLiquidityToProtocol(address _pair) external {
        uint liquidity = IERC20(_pair).balanceOf(address(this));
        require(liquidity != 0, "Workflow: has no balance");

        IERC20(_pair).approve(address(this), liquidity);
        IERC20(_pair).approve(QUICKSWAP_ROUTER, liquidity);

        emit LiquidityRemoveApproved(QUICKSWAP_ROUTER, _pair, liquidity);
    }

    function approveSwapToProtocol(address _tokenIn, uint256 _amountIn) external {
        IERC20(_tokenIn).approve(address(this), _amountIn);
        IERC20(_tokenIn).approve(QUICKSWAP_ROUTER, _amountIn);

        emit TokensSwapApproved(QUICKSWAP_ROUTER, _tokenIn, _amountIn);
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool, bytes memory ) {
        if (block.timestamp > interval + lastTimeStamp) {
            return(true, bytes(""));
        }

        return(false, bytes(""));
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if (block.timestamp > interval + lastTimeStamp) {
            lastTimeStamp = block.timestamp;

            _fetchLatestPrices();
        }
    }
}
