const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Factory", function () {
  let vaultfactory, testNFT, vault;
  it("Should deloy factory", async function () {
    const Vaultfactory = await hre.ethers.getContractFactory("VaultFactory");
    vaultfactory = await Vaultfactory.deploy();
    console.log("Vaultfactory deployed to:", vaultfactory.address);
  });
  it("Should deloy testNFT", async function () {
    const TestNFT = await hre.ethers.getContractFactory("TestNFT");
    testNFT = await TestNFT.deploy();
    console.log("TestNFT deployed to:", testNFT.address);
  });
  it("Should mint and approve some test NFTs", async function () {
    await testNFT.mint(10);
  });
  it("Should create vault", async function () {
    let [owner] = await ethers.getSigners();
    await vaultfactory.createVault(owner.address);

    const vaultAddr = await vaultfactory.getVault(owner.address);

    const Vault = await hre.ethers.getContractFactory("Vault");
    vault = await Vault.attach(vaultAddr);
    console.log("Vault deployed to:", vaultAddr);
  });
  it("Should approve vault", async function () {
    await testNFT.setApprovalForAll(vault.address, true);
  });
  it("Should deposit to vaults", async function () {
    await vault.deposit(testNFT.address, 1);
    await vault.deposit(testNFT.address, 2);
    await vault.deposit(testNFT.address, 3);
  });
  it("Should unlock 1 nft", async function () {
    await vault.unlock(testNFT.address, 1);
  });
  it("Should withdraw token 1 from vault", async function () {
    /*     await network.provider.send("evm_setNextBlockTimestamp", [162509760000]);
    await network.provider.send("evm_mine"); */
    await vault.withdraw(testNFT.address, 1);
  });
  it("Should unlock all nfts", async function () {
    await vault.unlockAll();
  });
  it("Should withdraw token 1 from vault", async function () {
    await vault.withdrawMultiple([2, 3]);
  });
});
