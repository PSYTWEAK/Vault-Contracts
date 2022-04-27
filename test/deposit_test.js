const { expect } = require("chai");
const { ethers } = require("hardhat");

const deposit_test = () => {
  describe("Testing Deposit()", function () {
    let vaultfactory, testNFT, vault;

    let requiredNumberOfUnlockedNFTs = 10;

    it("Set up test conditions", async function () {
      let [owner, nonOwner] = await ethers.getSigners();

      /*                 Deploy factory                          */

      const Vaultfactory = await hre.ethers.getContractFactory("VaultFactory");

      vaultfactory = await Vaultfactory.deploy();

      /*                 Create Vault                          */

      await vaultfactory.createVault(owner.address);

      const vaultAddr = await vaultfactory.getVault(owner.address);

      const Vault = await hre.ethers.getContractFactory("Vault");

      vault = await Vault.attach(vaultAddr);

      /*                 Deploy testNFT                          */

      const TestNFT = await hre.ethers.getContractFactory("TestNFT");

      testNFT = await TestNFT.deploy();

      /*                 Mint testNFTs                          */

      await testNFT.mint(requiredNumberOfUnlockedNFTs);

      await testNFT.setApprovalForAll(vault.address, true);

      await testNFT.connect(nonOwner).mint(20);
    });
    it("Depositing 3 test NFTs", async function () {
      let [owner] = await ethers.getSigners();

      await vault.deposit(testNFT.address, 1);

      await vault.deposit(testNFT.address, 2);

      await vault.deposit(testNFT.address, 3);

      requiredNumberOfUnlockedNFTs = requiredNumberOfUnlockedNFTs - 3;

      let balance = await testNFT.balanceOf(owner.address);

      expect(balance).to.equal(requiredNumberOfUnlockedNFTs);
    });
    it("Depositing already deposited NFTs (should fail)", async function () {
      let [owner] = await ethers.getSigners();

      let hasFailed = false;

      try {
        await vault.deposit(testNFT.address, 1);

        await vault.deposit(testNFT.address, 2);

        await vault.deposit(testNFT.address, 3);
      } catch (err) {
        hasFailed = true;
      }

      let balance = await testNFT.balanceOf(owner.address);

      expect(hasFailed).to.equal(true);
      expect(balance).to.equal(requiredNumberOfUnlockedNFTs);
    });
    it("Depositing as a non owner of the vault (should fail)", async function () {
      let [owner, nonOwner] = await ethers.getSigners();

      let hasFailed = false;

      try {
        await vault.connect(nonOwner).deposit(testNFT.address, 12);
      } catch (err) {
        hasFailed = true;
      }

      let balance = await testNFT.balanceOf(nonOwner.address);

      expect(hasFailed).to.equal(true);
      expect(balance).to.equal(20);
    });
  });
};

module.exports = {
  deposit_test,
};
