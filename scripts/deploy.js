const { ethers } = require("hardhat")

async function main() {
  const SwapEngine = await ethers.getContractFactory("SwapEngine");
  const swapEngine = await SwapEngine.deploy()
  console.log("VWAPcomponent Address: ", swapEngine.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
