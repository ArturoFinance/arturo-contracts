const { ethers } = require("hardhat")

async function main() {

  const PriceDataFeed = await ethers.getContractFactory("PriceDataFeed");
  const priceDataFeed = await PriceDataFeed.deploy(100000)
  console.log("PriceDataFeed Address: ", priceDataFeed.address);

  const QuickswapLiquidity = await ethers.getContractFactory("QuickswapLiquidity");
  const quickswapLiquidity = await QuickswapLiquidity.deploy()
  console.log("QuickswapLiquidity Address: ", quickswapLiquidity.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
