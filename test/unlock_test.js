const { expect } = require("chai");
const { ethers } = require("hardhat");

const { unlockData } = require(`./unlock_data.js`);

const unlock_test = () => {
  describe("Testing unlock()", function () {
    let vaultfactory, testNFT, vault;

    let requiredNumberOfUnlockedNFTs = 10;
    it("Set up test conditions", async function () {
      let [owner] = await ethers.getSigners();

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

      /*                 Deposit testNFTs                          */

      await vault.deposit([testNFT.address], [[1, 2, 3]]);

      requiredNumberOfUnlockedNFTs = requiredNumberOfUnlockedNFTs - 3;

      let balance = await testNFT.balanceOf(owner.address);

      expect(balance).to.equal(requiredNumberOfUnlockedNFTs);
    });

    it("Unlock token id 1", async function () {
      await vault.unlock(testNFT.address, 1);
    });
    it("Wait unlockDelay amount of time", async function () {
      await network.provider.send("evm_increaseTime", [unlockData.unlockDelay]);
      await network.provider.send("evm_mine");
    });
    it("Withdraw token id 1", async function () {
      let [owner] = await ethers.getSigners();

      await vault.withdraw(testNFT.address, 1);

      requiredNumberOfUnlockedNFTs = requiredNumberOfUnlockedNFTs + 1;

      let balance = await testNFT.balanceOf(owner.address);

      expect(balance).to.equal(requiredNumberOfUnlockedNFTs);
    });
    it("Unlock token id 2", async function () {
      await vault.unlock(testNFT.address, 2);
    });
    it("Withdraw token id 2 before unlockDelay amount of time (should fail)", async function () {
      let [owner] = await ethers.getSigners();

      let hasFailed = false;

      try {
        await vault.withdraw(testNFT.address, 2);
      } catch (err) {
        hasFailed = true;
      }

      let balance = await testNFT.balanceOf(owner.address);

      expect(hasFailed).to.equal(true);

      expect(balance).to.equal(requiredNumberOfUnlockedNFTs);
    });
    it("Wait unlockDelay amount of time", async function () {
      await network.provider.send("evm_increaseTime", [unlockData.unlockDelay]);
      await network.provider.send("evm_mine");
    });
    it("Withdraw token id 2 ", async function () {
      let [owner] = await ethers.getSigners();

      await vault.withdraw(testNFT.address, 2);

      requiredNumberOfUnlockedNFTs = requiredNumberOfUnlockedNFTs + 1;

      let balance = await testNFT.balanceOf(owner.address);

      expect(balance).to.equal(requiredNumberOfUnlockedNFTs);
    });
    it("Unlock as nonOwner (should fail)", async function () {
      let [owner, nonOwner] = await ethers.getSigners();

      let hasFailed = false;

      try {
        await vault.connect(nonOwner).unlock();
      } catch (err) {
        hasFailed = true;
      }

      expect(hasFailed).to.equal(true);
    });
  });
};

module.exports = {
  unlock_test,
};
