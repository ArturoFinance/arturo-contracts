const { ethers } = require("hardhat")

async function main() {

  // const PriceDataFeed = await ethers.getContractFactory("PriceDataFeed");
  // const priceDataFeed = await PriceDataFeed.deploy(100000)
  // console.log("PriceDataFeed Address: ", priceDataFeed.address);

  // const MockERC20Token = await ethers.getContractFactory("MockERC20Token");
  // const mockERC20Token = await MockERC20Token.deploy(
  //   "mock",
  //   "Mock",
  //   '0x6EB662716e3FF6e035Fc0c629eFD672dCb7b0341',
  //   10000000000
  // )
  // console.log("MockERC20Token Address: ", mockERC20Token.address);

  // const QuickswapLiquidity = await ethers.getContractFactory("QuickswapLiquidity");
  // const quickswapLiquidity = await QuickswapLiquidity.deploy()
  // console.log("QuickswapLiquidity Address: ", quickswapLiquidity.address);

  // const Workflow = await ethers.getContractFactory("Workflow");
  // const workflow = await Workflow.deploy()
  // console.log("Workflow Address: ", workflow.address);

  // const UniswapLiquidity = await ethers.getContractFactory("UniswapLiquidity");
  // const uniswapLiquidity = await UniswapLiquidity.deploy()
  // console.log("UniswapLiquidity Address: ", uniswapLiquidity.address);

  const SwapWorkflow = await ethers.getContractFactory("SwapWorkflow");
  const swapWorkflow = await SwapWorkflow.deploy()
  console.log("SwapWorkflow Address: ", swapWorkflow.address);

  const SwapResolver = await ethers.getContractFactory("SwapResolver");
  const swapResolver = await SwapResolver.deploy(swapWorkflow.address)
  console.log("SwapResolver Address: ", swapResolver.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
