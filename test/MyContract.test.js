import { expect } from "chai";
import { ethers } from "hardhat";

describe("MyContract", function () {
  let myContract;

  beforeEach(async function () {
    const MyContract = await ethers.getContractFactory("MyContract");
    myContract = await MyContract.deploy();
  });

  it("should set the value correctly", async function () {
    await myContract.setValue(42);
    expect(await myContract.value()).to.equal(42);
  });
});