// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  let [owner] = await ethers.getSigners();
  /*                 Deploy factory                          */

  /*   const Vaultfactory = await hre.ethers.getContractFactory("VaultFactory");

  const vaultfactory = await Vaultfactory.deploy();

  console.log(`VaultFactory deployed at: ${vaultfactory.address}`); */

  /*                 Create Vault                          */

  //   await vaultfactory.createVault(owner.address);

  // const vaultAddr = await vaultfactory.getVault(owner.address);

  const Vault = await hre.ethers.getContractFactory("Vault");

  const vault = await Vault.attach(
    "0x8a579a8355f078F06B4293c57eAeADF97173A249"
  );

  console.log(`Vault created at: ${vault.address}`);

  const TestNFT = await hre.ethers.getContractFactory("TestNFT");

  const testNFT = await TestNFT.attach(
    "0x3687aBa716bE597155ccEC1b0ae60F442989190c"
  );

  console.log(`TestNFT deployed at: ${testNFT.address}`);

  await vault.deposit([testNFT.address], [[3, 4, 5]]);
  await testNFT.mint(3);
  await testNFT.mint(3);
  await testNFT.mint(3);

  await vault.deposit([testNFT.address], [[6, 7, 8]]);

  /*                 Deploy testNFT                         */

  /*                 Mint testNFTs                          */

  /*   await testNFT.mint(3);
  await testNFT.mint(3);
  await testNFT.mint(3);
  await testNFT.mint(3);
  await testNFT.mint(3); npx hardhat verify --network arbitrum 0x8a579a8355f078F06B4293c57eAeADF97173A249 "0xEE4076E241a03aA624a2049312C0ec3A25c69227"
  await testNFT.mint(3);
  await testNFT.mint(3);
  await testNFT.mint(3);
  await testNFT.mint(3);
  await testNFT.mint(3);
  await testNFT.mint(3);

  await testNFT.setApprovalForAll(vault.address, true); */

  /*                 Deposit testNFTs                         */

  // await vault.deposit([testNFT.address], [[1, 2, 3]]);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
