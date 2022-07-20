const { expect } = require('chai')
const { ethers } = require("hardhat")

describe('ARTU Token', () => {
  before(async () => {
    const users = await ethers.getSigners()
    const [Alice] = users
    this.Alice = Alice
    const ArtuToken = await ethers.getContractFactory('ArtuToken')
    this.artuToken = await ArtuToken.deploy(
      'ARTU Token',
      'ARTU'
    )
  })

  it('check deploy requrements', async () => {
    expect(await this.artuToken.tokenName()).to.equals("ARTU Token")
    expect(await this.artuToken.tokenSymbol()).to.equals("ARTU")
  })

  it('mint', async () => {
    await expect(this.artuToken.connect(this.Alice).mint(this.Alice.address, 2000))
      .emit(this.artuToken, 'ArtuTokenMinted')
      .withArgs(this.Alice.address, 2000)
  })

  it('burn', async () => {
    await expect(this.artuToken.connect(this.Alice).burn(1500))
      .to.emit(this.artuToken, 'ArtuTokenBurnt')
      .withArgs(this.Alice.address, 1500)
    
    expect(await this.artuToken.balanceOf(this.Alice.address))
      .to.equal(500)
  })
})
