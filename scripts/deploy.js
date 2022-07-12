const { ethers } = require("hardhat")

async function main() {
  const LiquidityProvide = await ethers.getContractFactory("LiquidityProvide");
  const liquidityProvide = await LiquidityProvide.deploy()
  console.log("LiquidityProvide Address: ", liquidityProvide.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
