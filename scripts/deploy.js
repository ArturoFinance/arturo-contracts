const { ethers } = require("hardhat")

async function main() {
  const VWAPcomponent = await ethers.getContractFactory("VWAPcomponent");
  const component = await VWAPcomponent.deploy()
  console.log("VWAPcomponent Address: ", component.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
