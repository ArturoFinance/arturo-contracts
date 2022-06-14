// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

contract VWAPcomponent is Ownable {
    mapping(address => address) tokenPriceWatchList; // iterable map
    mapping(address => uint256) tokenPrices;
    mapping(address => address) proxyAddresses;
    uint256 public listSize;
    address constant BASE = address(1);

    constructor() {
        tokenPriceWatchList[BASE] = BASE;
    }

    function addToken(address _tokenAddr) external {
        require(!isToken(_tokenAddr), "VWAPcomponent: token already exists");
        tokenPriceWatchList[_tokenAddr] = tokenPriceWatchList[BASE];
        tokenPriceWatchList[BASE] = _tokenAddr;
        listSize ++;
    }

    function removeToken(address _tokenAddr) external onlyOwner {
        require(isToken(_tokenAddr), "VWAPcomponent: token doesn't exists");
        address prevToken = _getPrevToken(_tokenAddr);
        tokenPriceWatchList[prevToken] = tokenPriceWatchList[_tokenAddr];
        tokenPriceWatchList[_tokenAddr] = address(0);
        listSize --;
    }

    function _getPrevToken(address _tokenAddr) internal view returns (address) {
        address currentAddr = BASE;
        while(tokenPriceWatchList[currentAddr] != BASE) {
            if (tokenPriceWatchList[currentAddr] == _tokenAddr) {
                return currentAddr;
            }
            currentAddr = tokenPriceWatchList[currentAddr];
        }
        return address(0);
    }

    function isToken(address _tokenAddr) public view returns (bool) {
        return tokenPriceWatchList[_tokenAddr] != address(0);
    }

    function _getLatestTokenPrice(AggregatorV3Interface tokenPriceFeed)
        internal
        view
        returns (uint256)
    {
        (
            ,
            /*uint80 roundID*/
            int price, /*uint startedAt*/
            ,
            ,

        ) = /*uint timeStamp*/
            /*uint80 answeredInRound*/
            tokenPriceFeed.latestRoundData();
        return uint256(price);
    }

    function getStoredTokenPrices() external view returns (uint256[] memory) {
        uint256[] memory priceLists = new uint256[](listSize);
        address currentAddress = tokenPriceWatchList[BASE];

        for(uint256 i = 0; currentAddress != BASE; ++i) {
            uint256 price = getTokenPrice(currentAddress);
            priceLists[i] = price;
            currentAddress = tokenPriceWatchList[currentAddress];
        }

        return priceLists;
    }

    function getTokenPrice(address token) public view returns (uint256) {
        require(proxyAddresses[token] != address(0), "This token doesn't have its proxy address. Add proxy address.");

        address proxy = proxyAddresses[token];
        AggregatorV3Interface tokenPriceFeed = AggregatorV3Interface(proxy);
        uint256 price = _getLatestTokenPrice(tokenPriceFeed);
        return price;
    }

    function addTokenProxy(address _tokenAddr, address _proxyAddr) external {
        require(_tokenAddr != address(0), "Invalid token address");
        require(_proxyAddr != address(0), "Invalid proxy address");

        proxyAddresses[_tokenAddr] = _proxyAddr;
    }
    
}
