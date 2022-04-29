const { expect } = require("chai");
const { ethers } = require("hardhat");

const { unlockData } = require(`./unlock_data.js`);

const unlockAll_test = () => {
  describe("Testing unlockAll()", function () {
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

      await vault.deposit(testNFT.address, 1);

      await vault.deposit(testNFT.address, 2);

      await vault.deposit(testNFT.address, 3);

      requiredNumberOfUnlockedNFTs = requiredNumberOfUnlockedNFTs - 3;

      let balance = await testNFT.balanceOf(owner.address);

      expect(balance).to.equal(requiredNumberOfUnlockedNFTs);
    });

    it("UnlockAll tokens", async function () {
      await vault.unlockAll();
    });
    it("Wait unlockDelay amount of time", async function () {
      await network.provider.send("evm_increaseTime", [unlockData.unlockDelay]);
      await network.provider.send("evm_mine");
    });
    it("Withdraw All", async function () {
      let [owner] = await ethers.getSigners();

      await vault.withdrawMultipleOfCollection(testNFT.address, [1, 2, 3]);

      requiredNumberOfUnlockedNFTs = requiredNumberOfUnlockedNFTs + 3;

      let balance = await testNFT.balanceOf(owner.address);

      expect(balance).to.equal(requiredNumberOfUnlockedNFTs);
    });
    it("Deposit 3 more", async function () {
      let [owner] = await ethers.getSigners();
      await vault.deposit(testNFT.address, 4);

      await vault.deposit(testNFT.address, 5);

      await vault.deposit(testNFT.address, 6);

      requiredNumberOfUnlockedNFTs = requiredNumberOfUnlockedNFTs - 3;

      let balance = await testNFT.balanceOf(owner.address);

      expect(balance).to.equal(requiredNumberOfUnlockedNFTs);
    });
    it("Wait timeUntilUnlockExpires amount of time", async function () {
      await network.provider.send("evm_increaseTime", [
        unlockData.timeUntilUnlockExpires,
      ]);
      await network.provider.send("evm_mine");
    });
    it("UnlockAll tokens", async function () {
      await vault.unlockAll();
    });
    it("Withdraw token ids 4,5,6 before unlockDelay amount of time (should fail)", async function () {
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
    it("Withdraw all", async function () {
      let [owner] = await ethers.getSigners();

      await vault.withdrawMultipleOfCollection(testNFT.address, [4, 5, 6]);

      requiredNumberOfUnlockedNFTs = requiredNumberOfUnlockedNFTs + 3;

      let balance = await testNFT.balanceOf(owner.address);

      expect(balance).to.equal(requiredNumberOfUnlockedNFTs);
    });
    it("UnlockAll as nonOwner (should fail)", async function () {
      let [owner, nonOwner] = await ethers.getSigners();

      let hasFailed = false;

      try {
        await vault.connect(nonOwner).unlockAll();
      } catch (err) {
        hasFailed = true;
      }

      expect(hasFailed).to.equal(true);
    });
  });
};

module.exports = {
  unlockAll_test,
};
