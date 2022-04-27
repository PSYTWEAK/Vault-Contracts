const { expect } = require("chai");
const { ethers } = require("hardhat");
const { withdraw_test } = require(`./withdraw_test.js`);
const { deposit_test } = require(`./deposit_test.js`);
const {
  withdrawMultipleOfCollection_test,
} = require(`./withdrawMultipleOfCollection_test.js`);

describe("Unit Tests", function () {
  withdraw_test();
  deposit_test();
  withdrawMultipleOfCollection_test();
});
