const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Swappping", function () {
  before(async () => {
    const users = await ethers.getSigners()
    const [Alice, Bob] = users
    this.Alice = Alice
    this.Bob = Bob

    this.routerAddress = '0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff'
    this.wmaticAddress = '0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889'
    this.daiAddress = '0xcB1e72786A6eb3b44C2a2429e317c8a2462CFeb1'
    this.wmaticAmount = 1200000000000000
    this.wmaticABI = [
      { "constant": true, "inputs": [], "name": "name", "outputs": [{ "name": "", "type": "string" }], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": false, "inputs": [{ "name": "guy", "type": "address" }, { "name": "wad", "type": "uint256" }], "name": "approve", "outputs": [{ "name": "", "type": "bool" }], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": true, "inputs": [], "name": "totalSupply", "outputs": [{ "name": "", "type": "uint256" }], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": false, "inputs": [{ "name": "src", "type": "address" }, { "name": "dst", "type": "address" }, { "name": "wad", "type": "uint256" }], "name": "transferFrom", "outputs": [{ "name": "", "type": "bool" }], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [{ "name": "wad", "type": "uint256" }], "name": "withdraw", "outputs": [], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": true, "inputs": [], "name": "decimals", "outputs": [{ "name": "", "type": "uint8" }], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [{ "name": "", "type": "address" }], "name": "balanceOf", "outputs": [{ "name": "", "type": "uint256" }], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [], "name": "symbol", "outputs": [{ "name": "", "type": "string" }], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": false, "inputs": [{ "name": "dst", "type": "address" }, { "name": "wad", "type": "uint256" }], "name": "transfer", "outputs": [{ "name": "", "type": "bool" }], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [], "name": "deposit", "outputs": [], "payable": true, "stateMutability": "payable", "type": "function" }, { "constant": true, "inputs": [{ "name": "", "type": "address" }, { "name": "", "type": "address" }], "name": "allowance", "outputs": [{ "name": "", "type": "uint256" }], "payable": false, "stateMutability": "view", "type": "function" }, { "payable": true, "stateMutability": "payable", "type": "fallback" }, { "anonymous": false, "inputs": [{ "indexed": true, "name": "src", "type": "address" }, { "indexed": true, "name": "guy", "type": "address" }, { "indexed": false, "name": "wad", "type": "uint256" }], "name": "Approval", "type": "event" }, { "anonymous": false, "inputs": [{ "indexed": true, "name": "src", "type": "address" }, { "indexed": true, "name": "dst", "type": "address" }, { "indexed": false, "name": "wad", "type": "uint256" }], "name": "Transfer", "type": "event" }, { "anonymous": false, "inputs": [{ "indexed": true, "name": "dst", "type": "address" }, { "indexed": false, "name": "wad", "type": "uint256" }], "name": "Deposit", "type": "event" }, { "anonymous": false, "inputs": [{ "indexed": true, "name": "src", "type": "address" }, { "indexed": false, "name": "wad", "type": "uint256" }], "name": "Withdrawal", "type": "event" }
    ]

    const SwapContract = await ethers.getContractFactory("SwapWorkflow")
    this.swapContract = await SwapContract.deploy()

    this.wmaticContract = await new ethers.Contract(this.wmaticAddress, this.wmaticABI, ethers.provider)
  })

  it("Approve the router to call functions", async () => {
    await expect(this.swapContract.connect(this.Alice).approveSwapToProtocol(
      this.wmaticAddress,
      this.wmaticAmount
    )).emit(this.swapContract, "TokensSwapApproved")
      .withArgs(this.routerAddress, this.wmaticAddress, this.wmaticAmount)
  })

  it("Swap on Quickswap", async () => {
    await this.wmaticContract.connect(this.Alice).approve(this.swapContract.address, this.wmaticAmount)

    await expect(this.swapContract.connect(this.Alice).swap(
      this.Alice.address,
      this.wmaticAddress,
      this.daiAddress,
      this.wmaticAmount,
      100000
    )).emit(this.swapContract, "TokensSwapped")
      .withArgs(this.wmaticAddress, this.daiAddress, this.Alice.address)
  })
});
