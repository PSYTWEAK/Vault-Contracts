const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Factory", function () {
  let vaultfactory, testNFT, vault;
  it("Test deploying the vaultfactory contract", async function () {
    const Vaultfactory = await hre.ethers.getContractFactory("VaultFactory");

    vaultfactory = await Vaultfactory.deploy();
  });
  it("deploy testNFT", async function () {
    const TestNFT = await hre.ethers.getContractFactory("TestNFT");
    testNFT = await TestNFT.deploy();
  });
  it("mint testNFT", async function () {
    let [owner] = await ethers.getSigners();
    await testNFT.mint(10);

    let balance = await testNFT.balanceOf(owner.address);

    expect(balance).to.equal(10);
  });
  it("Test creating Vault from using vault factory", async function () {
    let [owner] = await ethers.getSigners();

    await vaultfactory.createVault(owner.address);

    const vaultAddr = await vaultfactory.getVault(owner.address);

    const Vault = await hre.ethers.getContractFactory("Vault");

    vault = await Vault.attach(vaultAddr);
  });
  it("approve vault", async function () {
    await testNFT.setApprovalForAll(vault.address, true);
  });
  it("test depositing 3 NFTs", async function () {
    let [owner] = await ethers.getSigners();
    await vault.deposit(testNFT.address, 1);

    await vault.deposit(testNFT.address, 2);

    await vault.deposit(testNFT.address, 3);

    let balance = await testNFT.balanceOf(owner.address);

    expect(balance).to.equal(7);
  });
  it("test depositing same 3 NFTs (should fail)", async function () {
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
    expect(balance).to.equal(7);
  });
  it("Test withdraw token 1 from vault without unlocking (should fail)", async function () {
    let [owner] = await ethers.getSigners();
    let hasFailed = false;

    try {
      await vault.withdraw(testNFT.address, 1);
    } catch (err) {
      hasFailed = true;
    }

    let balance = await testNFT.balanceOf(owner.address);

    expect(hasFailed).to.equal(true);
    expect(balance).to.equal(7);
  });
  it("Test unlock token id 1", async function () {
    await vault.unlock(testNFT.address, 1);

    /*     let unlockTimestamp = await vault.getTimestampForSingleNFTUnlocked(
      testNFT.address,
      1
    );

    expect(unlockTimestamp).to.greaterThan(0); */
  });
  it("Test withdraw token id 1", async function () {
    let [owner] = await ethers.getSigners();
    await vault.withdraw(testNFT.address, 1);

    let balance = await testNFT.balanceOf(owner.address);

    expect(balance).to.equal(8);
  });
  it("Test withdraw token id 2 before unlocking (should fail)", async function () {
    let [owner] = await ethers.getSigners();
    let hasFailed = false;

    try {
      await vault.withdraw(testNFT.address, 2);
    } catch (err) {
      hasFailed = true;
    }

    let balance = await testNFT.balanceOf(owner.address);

    expect(hasFailed).to.equal(true);
    expect(balance).to.equal(8);
  });
  it("Test unlock all NFTs", async function () {
    await vault.unlockAll();

    /*     let unlockTimestamp = await vault.getTimestampForAllNFTsUnlocked();

    expect(unlockTimestamp).to.greaterThan(0); */
  });
  it("Test withdraw mutiple tokens 2 & 3 from vault in same tx", async function () {
    let [owner] = await ethers.getSigners();

    await vault.withdrawMultiple([testNFT.address], [[2, 3]]);

    let balance = await testNFT.balanceOf(owner.address);

    expect(balance).to.equal(10);
  });
});
