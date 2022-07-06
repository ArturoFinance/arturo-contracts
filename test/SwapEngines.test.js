const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Swappping", function () {
  before(async () => {
    const users = await ethers.getSigners()
    const [Alice, Bob] = users
    this.Alice = Alice
    this.Bob = Bob
    this.enginTypes = {
      Apeswap: 0,
      UniswapV2: 1,
      UniswapV3: 2,
      Sushiswap: 3,
      Oneinch: 4
    }

    this.quickswapRouterAddress = '0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff'
    this.UniswapV2RouterAddress = '0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45'
    this.UniswapV3RouterAddress = '0xE592427A0AEce92De3Edee1F18E0157C05861564'
    this.wmaticAddress = '0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889'
    this.daiAddress = '0xcB1e72786A6eb3b44C2a2429e317c8a2462CFeb1'
    this.wmaticAmount = 1000000000000
    this.expectedDaiOutput = 303544764287
    this.wmaticABI = [
      { "constant": true, "inputs": [], "name": "name", "outputs": [{ "name": "", "type": "string" }], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": false, "inputs": [{ "name": "guy", "type": "address" }, { "name": "wad", "type": "uint256" }], "name": "approve", "outputs": [{ "name": "", "type": "bool" }], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": true, "inputs": [], "name": "totalSupply", "outputs": [{ "name": "", "type": "uint256" }], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": false, "inputs": [{ "name": "src", "type": "address" }, { "name": "dst", "type": "address" }, { "name": "wad", "type": "uint256" }], "name": "transferFrom", "outputs": [{ "name": "", "type": "bool" }], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [{ "name": "wad", "type": "uint256" }], "name": "withdraw", "outputs": [], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": true, "inputs": [], "name": "decimals", "outputs": [{ "name": "", "type": "uint8" }], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [{ "name": "", "type": "address" }], "name": "balanceOf", "outputs": [{ "name": "", "type": "uint256" }], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [], "name": "symbol", "outputs": [{ "name": "", "type": "string" }], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": false, "inputs": [{ "name": "dst", "type": "address" }, { "name": "wad", "type": "uint256" }], "name": "transfer", "outputs": [{ "name": "", "type": "bool" }], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [], "name": "deposit", "outputs": [], "payable": true, "stateMutability": "payable", "type": "function" }, { "constant": true, "inputs": [{ "name": "", "type": "address" }, { "name": "", "type": "address" }], "name": "allowance", "outputs": [{ "name": "", "type": "uint256" }], "payable": false, "stateMutability": "view", "type": "function" }, { "payable": true, "stateMutability": "payable", "type": "fallback" }, { "anonymous": false, "inputs": [{ "indexed": true, "name": "src", "type": "address" }, { "indexed": true, "name": "guy", "type": "address" }, { "indexed": false, "name": "wad", "type": "uint256" }], "name": "Approval", "type": "event" }, { "anonymous": false, "inputs": [{ "indexed": true, "name": "src", "type": "address" }, { "indexed": true, "name": "dst", "type": "address" }, { "indexed": false, "name": "wad", "type": "uint256" }], "name": "Transfer", "type": "event" }, { "anonymous": false, "inputs": [{ "indexed": true, "name": "dst", "type": "address" }, { "indexed": false, "name": "wad", "type": "uint256" }], "name": "Deposit", "type": "event" }, { "anonymous": false, "inputs": [{ "indexed": true, "name": "src", "type": "address" }, { "indexed": false, "name": "wad", "type": "uint256" }], "name": "Withdrawal", "type": "event" }
    ]

    const SwapContract = await ethers.getContractFactory("SwapWorkflow")
    this.swapContract = await SwapContract.deploy()

    const SwapEngine = await ethers.getContractFactory("SwapEngine")
    this.swapEngine = await SwapEngine.deploy()

    this.wmaticContract = await new ethers.Contract(this.wmaticAddress, this.wmaticABI, ethers.provider)
  })

  it("Approve the quickswap router to call functions", async () => {
    await expect(this.swapContract.connect(this.Alice).approveSwapToProtocol(
      this.wmaticAddress,
      this.wmaticAmount
    )).emit(this.swapContract, "TokensSwapApproved")
      .withArgs(this.quickswapRouterAddress, this.wmaticAddress, this.wmaticAmount)
  })

  it("Swap on Quickswap", async () => {
    await expect(this.wmaticContract.connect(this.Alice).approve(this.swapContract.address, this.wmaticAmount))
      .emit(this.wmaticContract, "Approval")
      .withArgs(this.Alice.address, this.swapContract.address, this.wmaticAmount)

      // console.log(await this.swapContract.connect(this.Alice).swap(
      //   this.Alice.address,
      //   this.wmaticAddress,
      //   this.daiAddress,
      //   this.wmaticAmount,
      //   100000,
      //   { gasLimit: 300000 }
      // ))
    this.swapContract.connect(this.Alice).swap(
      this.Alice.address,
      this.wmaticAddress,
      this.daiAddress,
      this.wmaticAmount,
      100000,
      { gasLimit: 300000 }
    )
  })

  it("Approve the uniswap v2 router to call functions", async () => {
    await expect(this.swapEngine.connect(this.Alice).approveSwapOnEngines(
      this.wmaticAddress,
      this.wmaticAmount,
      this.enginTypes.UniswapV2
    )).emit(this.swapEngine, "TokensApprovedOnUniswapV2")
      .withArgs(this.UniswapV2RouterAddress, this.wmaticAddress, this.wmaticAmount)
  })

  it("Swapping failed because of unknown swap type", async () => {
    await expect(this.swapEngine.connect(this.Alice).swapOnUniswapV2(
      this.Alice.address,
      this.wmaticAddress,
      this.daiAddress,
      hre.ethers.utils.parseEther(this.wmaticAmount),
      this.enginTypes.UniswapV3
    )).to.revertedWith("Please call a reasonable function")
  })

  it("Swap on Uniswap v2", async () => {
    await expect(this.wmaticContract.connect(this.Alice).approve(this.swapEngine.address, this.wmaticAmount))
      .emit(this.wmaticContract, "Approval")
      .withArgs(this.Alice.address, this.swapEngine.address, this.wmaticAmount)

    await this.swapEngine.connect(this.Alice).swapOnUniswapV2(
      this.Alice.address,
      this.wmaticAddress,
      this.daiAddress,
      this.wmaticAmount,
      this.enginTypes.UniswapV2,
      { gasLimit: 300000 }
    )
  })

  it("Approve the uniswap v3 router to call functions", async () => {
    await expect(this.swapEngine.connect(this.Alice).approveSwapOnEngines(
      this.wmaticAddress,
      this.wmaticAmount,
      this.enginTypes.UniswapV3
    )).emit(this.swapEngine, "TokensApprovedOnUniswapV3")
      .withArgs(this.UniswapV3RouterAddress, this.wmaticAddress, this.wmaticAmount)
  })

  it("Swap on Uniswap v3", async () => {
    await this.wmaticContract.connect(this.Alice).approve(this.swapEngine.address, this.wmaticAmount)

    await expect(this.swapEngine.connect(this.Alice).swapOnUniswapV3(
      this.Alice.address,
      this.wmaticAddress,
      this.daiAddress,
      this.wmaticAmount,
      this.enginTypes.UniswapV3,
      { gasLimit: 300000 }
    )).emit(this.swapEngine, "TokensSwappedOnUniswapV3")
      .withArgs(this.wmaticAddress, this.daiAddress, this.Alice.address)
  })
});
