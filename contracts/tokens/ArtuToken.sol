// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArtuToken is ERC20, Ownable {
    event ArtuTokenMinted(address _recipient, uint256 _amount);
    event ArtuTokenBurnt(address _from, uint256 _amount);

    string public tokenName;
    string public tokenSymbol;
    /**
     * @dev constructor
     * @param _erc20Name token name
     * @param _erc20Symbol token symbol
     */
    constructor(
        string memory _erc20Name,
        string memory _erc20Symbol
    ) ERC20(_erc20Name, _erc20Symbol) {
        tokenName = _erc20Name;
        tokenSymbol = _erc20Symbol;
    }

    function mint(address _recipient, uint256 _amount) external onlyOwner {
        require(_recipient != address(0), "ARTU: invalid recipient address");
        require(_amount != 0, "ARTU: amount can not be zero");

        _mint(_recipient, _amount);

        emit ArtuTokenMinted(_recipient, _amount);
    }
    /**
     * @dev anyone can burn tokens in their own address
     * @param _amount token amount to burn
     */
    function burn(uint256 _amount) external {
        require(_amount != 0, "ARTU: amount can not be zero");

        _burn(msg.sender, _amount);

        emit ArtuTokenBurnt(msg.sender, _amount);
    }
}
