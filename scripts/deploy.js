// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  let vaultfactory, testNFT, vault;

  const Vaultfactory = await hre.ethers.getContractFactory("VaultFactory");
  vaultfactory = await Vaultfactory.deploy();
  console.log("Vaultfactory deployed to:", vaultfactory.address);

  const TestNFT = await hre.ethers.getContractFactory("TestNFT");
  testNFT = await TestNFT.deploy();
  console.log("TestNFT deployed to:", testNFT.address);

  await testNFT.mint(10);
  let [owner] = await ethers.getSigners();
  await vaultfactory.createVault(testNFT.address, owner.address);

  const vaultAddr = await vaultfactory.getVault(owner.address, testNFT.address);

  const Vault = await hre.ethers.getContractFactory("Vault");
  vault = await Vault.attach(vaultAddr);
  console.log("Vault deployed to:", vaultAddr);

  await testNFT.setApprovalForAll(vault.address, true);

  await vault.deposit(1);
  await vault.deposit(2);
  await vault.deposit(3);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
