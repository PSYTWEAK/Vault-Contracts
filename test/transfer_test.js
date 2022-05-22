const { expect } = require("chai");
const { ethers } = require("hardhat");
const { unlockData } = require(`./unlock_data.js`);

const transfer_test = () => {
  describe("Testing transfer()", function () {
    let vaultfactory, testNFT, vault, lockedERC721;

    let requiredNumberOfLockedNFTs = 0;
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

      await testNFT.mint(3);

      await testNFT.setApprovalForAll(vault.address, true);

      /*                 Deposit testNFTs                          */

      await vault.deposit([testNFT.address], [[1, 2, 3]]);

      requiredNumberOfLockedNFTs = 3;

      let lockedTokenAddr = await vault.getLockedERC721(testNFT.address);

      const LockedERC721 = await hre.ethers.getContractFactory("LockedERC721");

      lockedERC721 = await LockedERC721.attach(lockedTokenAddr);

      let balance = await lockedERC721.balanceOf(owner.address);

      expect(balance).to.equal(requiredNumberOfLockedNFTs);
    });
    it("transfer locked token (should fail)", async function () {
      let [owner, nonOwner] = await ethers.getSigners();
      let hasFailed = false;

      try {
        await lockedERC721.transferFrom(owner.address, nonOwner.address, 1);
      } catch (err) {
        hasFailed = true;
      }

      let balance = await lockedERC721.balanceOf(owner.address);

      expect(balance).to.equal(requiredNumberOfLockedNFTs);
      expect(hasFailed).to.equal(true);
    });
  });
};

module.exports = {
  transfer_test,
};
