const { expect } = require("chai");
const { ethers } = require("hardhat");
const { unlockData } = require(`./unlock_data.js`);

const transfer_test = () => {
  describe("Testing transfer()", function () {
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

      await vault.deposit([testNFT.address], [[4, 5, 6, 7]]);

      requiredNumberOfUnlockedNFTs = requiredNumberOfUnlockedNFTs - 7;

      let balance = await testNFT.balanceOf(owner.address);

      expect(balance).to.equal(requiredNumberOfUnlockedNFTs);
    });
    it("Withdraw token id 1 & 2 from vault without unlocking (should fail)", async function () {
      let [owner] = await ethers.getSigners();
      let hasFailed = false;

      try {
        await vault.withdraw([testNFT.address], [[1, 2]]);
      } catch (err) {
        hasFailed = true;
      }

      let balance = await testNFT.balanceOf(owner.address);

      expect(hasFailed).to.equal(true);

      expect(balance).to.equal(requiredNumberOfUnlockedNFTs);
    });
    it("Unlock token id 1 & 2", async function () {
      await vault.unlock(testNFT.address, 1);
      await vault.unlock(testNFT.address, 2);
    });
    it("Wait unlockDelay amount of time", async function () {
      await network.provider.send("evm_increaseTime", [unlockData.unlockDelay]);
      await network.provider.send("evm_mine");
    });
    it("Withdraw token id 1", async function () {
      let [owner] = await ethers.getSigners();

      await vault.withdraw([testNFT.address], [[1, 2]]);

      requiredNumberOfUnlockedNFTs = requiredNumberOfUnlockedNFTs + 2;

      let balance = await testNFT.balanceOf(owner.address);

      expect(balance).to.equal(requiredNumberOfUnlockedNFTs);
    });
    it("Withdraw token id 3 & 4 before unlocking (should fail)", async function () {
      let [owner] = await ethers.getSigners();

      let hasFailed = false;

      try {
        await vault.withdraw([testNFT.address], [[3, 4]]);
      } catch (err) {
        hasFailed = true;
      }

      let balance = await testNFT.balanceOf(owner.address);

      expect(hasFailed).to.equal(true);

      expect(balance).to.equal(requiredNumberOfUnlockedNFTs);
    });
    it("Unlock all NFTs", async function () {
      await vault.unlockAll();
    });
    it("Wait unlockDelay amount of time", async function () {
      await network.provider.send("evm_increaseTime", [unlockData.unlockDelay]);
      await network.provider.send("evm_mine");
    });
    it("Withdraw token id 3 & 4", async function () {
      let [owner] = await ethers.getSigners();

      await vault.withdraw([testNFT.address], [[3, 4]]);

      requiredNumberOfUnlockedNFTs = requiredNumberOfUnlockedNFTs + 2;

      let balance = await testNFT.balanceOf(owner.address);

      expect(balance).to.equal(requiredNumberOfUnlockedNFTs);
    });

    it("Withdraw token id 5 & 6 as a non owner of the vault (should fail)", async function () {
      let [owner, nonOwner] = await ethers.getSigners();

      let hasFailed = false;

      try {
        await vault.connect(nonOwner).withdraw([testNFT.address], [[5, 6]]);
      } catch (err) {
        hasFailed = true;
      }

      let balance = await testNFT.balanceOf(nonOwner.address);

      expect(hasFailed).to.equal(true);
      expect(balance).to.equal(0);
    });
    it("Withdraw single token id 7", async function () {
      let [owner] = await ethers.getSigners();

      await vault.withdraw([testNFT.address], [[7]]);

      requiredNumberOfUnlockedNFTs = requiredNumberOfUnlockedNFTs + 1;

      let balance = await testNFT.balanceOf(owner.address);

      expect(balance).to.equal(requiredNumberOfUnlockedNFTs);
    });
    it("Withdraw single token id 7 after already been withdrawn (should fail)", async function () {
      let [owner] = await ethers.getSigners();

      try {
        await vault.withdraw([testNFT.address], [[7]]);
      } catch (err) {
        hasFailed = true;
      }

      let balance = await testNFT.balanceOf(owner.address);

      expect(balance).to.equal(requiredNumberOfUnlockedNFTs);
    });
  });
};

module.exports = {
  transfer_test,
};
