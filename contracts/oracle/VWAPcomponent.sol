// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VWAPcomponent is Ownable {
    mapping(address => address) tokenPriceWatchList; // iterable map
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
}
