const { expect } = require("chai");
const { ethers } = require("hardhat");
const { unlockData } = require(`./unlock_data.js`);

const emergencyTransferOwnership_test = () => {
  describe("Testing acceptEmergencyInviteForBackupAddressToTakeControl()", function () {
    let vaultfactory, testNFT, testNFT2, vault;

    let requiredNumberOfUnlockedNFTs = 10;

    it("Set up test conditions", async function () {
      let [owner, nonOwner] = await ethers.getSigners();

      /*                 Deploy factory                          */

      const Vaultfactory = await hre.ethers.getContractFactory("VaultFactory");

      vaultfactory = await Vaultfactory.deploy();

      /*                 Create Vault                          */

      await vaultfactory.createVault(nonOwner.address);

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

      await testNFT.connect(nonOwner).setApprovalForAll(vault.address, true);
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
    it("Sign message and invite emergency back up to take over", async function () {
      let [owner, newOwner] = await ethers.getSigners();

      let signedMess = await owner.signMessage("Invite");

      console.log(signedMess);

      await vault
        .connect(newOwner)
        .acceptEmergencyInviteForBackupAddressToTakeControl(signedMess);
    });
    it("Depositing as a new owner of the vault", async function () {
      let [owner, newOwner] = await ethers.getSigners();

      await vault.connect(newOwner).deposit(testNFT.address, 12);
    });
  });
};

module.exports = {
  emergencyTransferOwnership_test,
};
