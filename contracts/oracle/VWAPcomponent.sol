// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VWAPcomponent is Ownable {
    address[] public tokenAddreses;

    constructor() {}

    function addToken(address _tokenAddr) external onlyOwner {
        tokenAddreses.push(_tokenAddr);
    }

    function removeToken(address _tokenAddr) external onlyOwner {
        for (uint256 i; i < tokenAddreses.length; i++) {
            if (tokenAddreses[i] == _tokenAddr) {
                tokenAddreses[i] = tokenAddreses[tokenAddreses.length - 1];
                tokenAddreses.pop();
                break;
            }
        }
    }
}
