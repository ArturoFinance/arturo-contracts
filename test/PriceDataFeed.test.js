const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PriceDataFeed", function () {
  it("Deploy the contract", async function () {
    const PriceDataFeed = await ethers.getContractFactory("PriceDataFeed");
    const priceDataFeed = await PriceDataFeed.deploy(60);
    await priceDataFeed.deployed();
  });
});
