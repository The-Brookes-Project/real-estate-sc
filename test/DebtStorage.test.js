const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

const { DebtStatus, Currency } = require("./utils");

describe("DebtStorage", function () {
  let debtStorage;
  let owner;
  let versepropFeeWallet;
  let secondFeeWallet;
  let manager;
  let debtor;
  let usdcTokenAddress = "0x036CbD53842c5426634e7929541eC2318f3dCF7e";

  beforeEach(async function () {
    [owner, debtor, manager, versepropFeeWallet, secondFeeWallet] =
      await ethers.getSigners();

    // Deploy DebtStorage
    const DebtStorage = await ethers.getContractFactory("DebtStorage");
    debtStorage = await DebtStorage.deploy(
      owner.address,
      versepropFeeWallet.address,
      usdcTokenAddress
    );
    await debtStorage.connect(owner).addManager(manager.address);
  });

  it("should allow owner to get and add a debt", async function () {
    const debtId = await debtStorage.debtCount();
    expect(debtId).to.equal(0);
    const newDebt = {
      maxAmount: ethers.parseEther("5000"),
      interestRate: 500, // 5%
      term: 12, // 12 months
      walletAddress: debtor.address,
      minInvestmentAmount: ethers.parseEther("100"),
      totalInvestment: ethers.parseEther("0"),
      status: DebtStatus.OPEN,
      startDate: 0,
      settledDate: 0,
      nftContractAddress: ethers.ZeroAddress,
      tokenURI: "",
      currency: Currency.ETH,
    };
    await debtStorage.connect(manager).addDebt(newDebt);
    const updatedDebtCount = await debtStorage.debtCount();
    expect(updatedDebtCount).to.equal(1);

    // Check the debt fields
    const storedDebt = await debtStorage.getDebt(debtId);
    expect(storedDebt.maxAmount.toString()).to.equal(
      newDebt.maxAmount.toString()
    );
    expect(storedDebt.interestRate.toString()).to.equal(
      newDebt.interestRate.toString()
    );
    expect(storedDebt.term.toString()).to.equal(newDebt.term.toString());
    expect(storedDebt.walletAddress.toString()).to.equal(
      newDebt.walletAddress.toString()
    );
    expect(storedDebt.minInvestmentAmount.toString()).to.equal(
      newDebt.minInvestmentAmount.toString()
    );
    expect(storedDebt.totalInvestment.toString()).to.equal(
      newDebt.totalInvestment.toString()
    );
    expect(storedDebt.status.toString()).to.equal(newDebt.status.toString());
    expect(storedDebt.startDate.toString()).to.equal(
      newDebt.startDate.toString()
    );
    expect(storedDebt.settledDate.toString()).to.equal(
      newDebt.settledDate.toString()
    );
    expect(storedDebt.nftContractAddress.toString()).to.equal(
      newDebt.nftContractAddress.toString()
    );
    expect(storedDebt.tokenURI.toString()).to.equal(
      newDebt.tokenURI.toString()
    );
    expect(storedDebt.currency.toString()).to.equal(
      newDebt.currency.toString()
    );

    await expect(
      debtStorage.connect(debtor).addDebt(newDebt)
    ).to.be.revertedWith("Caller is not a manager");
  });

  it("should allow owner to set the feeWallet", async function () {
    const _feeWallet = await debtStorage.feeWallet();
    expect(_feeWallet).to.equal(versepropFeeWallet);

    // Owner should be able to update the feeWallet
    await debtStorage.connect(owner).setFeeWallet(secondFeeWallet);
    const _updatedFeeWallet = await debtStorage.feeWallet();
    expect(_updatedFeeWallet).to.equal(secondFeeWallet);

    // Non-owner should not be allowed to update it
    await expect(
      debtStorage.connect(debtor).setFeeWallet(versepropFeeWallet)
    ).to.be.revertedWith("Caller is not an admin");
  });

  it("should update the debt", async function () {
    const _feeWallet = await debtStorage.feeWallet();
    expect(_feeWallet).to.equal(versepropFeeWallet);

    // Owner should be able to update the feeWallet
    await debtStorage.connect(owner).setFeeWallet(secondFeeWallet);

    const _updatedFeeWallet = await debtStorage.feeWallet();
    expect(_updatedFeeWallet).to.equal(secondFeeWallet);

    // Non-owner should not be allowed to update it
    await expect(
      debtStorage.connect(debtor).setFeeWallet(versepropFeeWallet)
    ).to.be.revertedWith("Caller is not an admin");
  });
});
