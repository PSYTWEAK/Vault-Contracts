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

      await vault.deposit([testNFT.address], [[1, 2, 3]]);

      requiredNumberOfUnlockedNFTs = requiredNumberOfUnlockedNFTs - 3;

      let balance = await testNFT.balanceOf(owner.address);

      expect(balance).to.equal(requiredNumberOfUnlockedNFTs);
    });
    it("Sign message and invite emergency back up to take over", async function () {
      let [owner, newOwner] = await ethers.getSigners();

      let message = "Invite";

      let messageHash = await vault.getMessageHash(message);
      let signature = await owner.signMessage(messageHash);
      let ethSignedMessage = await vault.getEthSignedMessageHash(messageHash);
      let recoverSigner = await vault.recoverSigner(
        ethSignedMessage,
        signature
      );

      console.log(`The message we signing: ${message}`);
      console.log(`The hashed message: ${messageHash}`);
      console.log(`The signature: ${signature}`);
      console.log(`The ETH signed message: ${ethSignedMessage}`);
      console.log(`The expected signer: ${owner.address}`);
      console.log(`The signer: ${recoverSigner}`);

      await vault
        .connect(newOwner)
        .acceptEmergencyInviteForBackupAddressToTakeControl(signature);
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
