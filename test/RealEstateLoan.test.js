const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("debtLogicContract", function () {
  let debtLogic;
  let debtProxy;
  let debtStorage;
  let debtNFT;
  let owner;
  let investor1;
  let investor2;
  let walletAddress;
  let tokenURI = "https://verseprop-byd6bdg5exfnayd3.z02.azurefd.net/static/raven.png";
  let usdcTokenAddress = "0x036CbD53842c5426634e7929541eC2318f3dCF7e";
  let versepropFeeWallet;

  beforeEach(async function () {
    [owner, investor1, investor2, walletAddress, versepropFeeWallet] = await ethers.getSigners();

    // Deploy DebtStorage
    const DebtStorage = await ethers.getContractFactory("DebtStorage");
    debtStorage = await DebtStorage.deploy(owner, versepropFeeWallet.address);

    // Deploy DebtLogic with the address of DebtStorage
    const DebtLogic = await ethers.getContractFactory("DebtLogic");
    debtLogic = await upgrades.deployProxy(DebtLogic, [debtStorage.address, usdcTokenAddress], { initializer: 'initialize' });

    const DebtAdmin = await ethers.getContractFactory("DebtAdmin");
    debtLogic = await upgrades.deployProxy(DebtLogic, [debtStorage.address, usdcTokenAddress], { initializer: 'initialize' });

    await debtLogic.deployed();
  });

  it("should create a new debt", async function () {
    const amount = ethers.utils.parseEther("1000000");
    const interestRate = 1000; // 10%
    const term = 9; // 9 months
    const investmentAmount = ethers.utils.parseEther("25000");

    await debtLogic.createDebt(amount, interestRate, term, walletAddress.address, investmentAmount, tokenURI);

    // Assuming you have a getter for debt details or indexing debts by ID
    const debtId = 0; // Using 0 as an example, adjust based on how you're indexing
    const debt = await debtLogic.getDebt(debtId);

    expect(debt.amount.toString()).to.equal(amount.toString());
    expect(debt.interestRate).to.equal(interestRate);
    expect(debt.term).to.equal(term);
    expect(debt.walletAddress).to.equal(walletAddress.address);
    expect(debt.investmentAmount.toString()).to.equal(investmentAmount.toString());
    // Adjust assertions based on actual return types and structures
  });

  // it("should allow investors to add deposits", async function () {
  //   const amount = ethers.parseEther("100");
  //   const interestRate = 1000; // 10%
  //   const term = 9; // 9 months
  //   const investmentAmount = ethers.parseEther("25");
  //
  //   await debtLogicContract.createDebt(amount, interestRate, term, walletAddress.address, investmentAmount, tokenURI);
  //
  //   await debtLogicContract.connect(investor1).addDeposit(1, { value: ethers.parseEther("50") });
  //   await debtLogicContract.connect(investor2).addDeposit(1, { value: ethers.parseEther("50") });
  //
  //   const debt = await debtLogicContract.debts(1);
  //   expect(debt.totalInvestment).to.equal(amount);
  //   expect(await debtLogicContract.investments(1, investor1.address)).to.equal(ethers.parseEther("50"));
  //   expect(await debtLogicContract.investments(1, investor2.address)).to.equal(ethers.parseEther("50"));
  // });
  //
  // it("should disburse the loan when the investment goal is reached", async function () {
  //   const amount = ethers.parseEther("100");
  //   const interestRate = 1000; // 10%
  //   const term = 9; // 9 months
  //   const investmentAmount = ethers.parseEther("25");
  //
  //   await debtLogicContract.createDebt(amount, interestRate, term, walletAddress.address, investmentAmount, tokenURI);
  //
  //   await debtLogicContract.connect(investor1).addDeposit(1, { value: ethers.parseEther("50") });
  //   await debtLogicContract.connect(investor2).addDeposit(1, { value: ethers.parseEther("50") });
  //
  //   const walletBalanceBefore = await ethers.provider.getBalance(walletAddress.address);
  //   await debtLogicContract.disburseLoan(1);
  //   const walletBalanceAfter = await ethers.provider.getBalance(walletAddress.address);
  //
  //   const verseProFee = amount * BigInt(2) / BigInt(100);
  //   const loanAmount = amount - verseProFee;
  //
  //   expect(walletBalanceAfter - walletBalanceBefore).to.equal(loanAmount);
  //
  //   const debt = await debtLogicContract.debts(1);
  //   expect(debt.disbursed).to.equal(true);
  // });
  //
  // it("should return deposits if the loan is not disbursed", async function () {
  //   const amount = ethers.parseEther("100");
  //   const interestRate = 1000; // 10%
  //   const term = 9; // 9 months
  //   const investmentAmount = ethers.parseEther("25");
  //
  //   await debtLogicContract.createDebt(amount, interestRate, term, walletAddress.address, investmentAmount, tokenURI);
  //
  //   await debtLogicContract.connect(investor1).addDeposit(1, { value: ethers.parseEther("50") });
  //   await debtLogicContract.connect(investor2).addDeposit(1, { value: ethers.parseEther("50") });
  //
  //   const investor1BalanceBefore = await ethers.provider.getBalance(investor1.address);
  //   const investor2BalanceBefore = await ethers.provider.getBalance(investor2.address);
  //
  //   await debtLogicContract.returnDeposit(1);
  //
  //   const investor1BalanceAfter = await ethers.provider.getBalance(investor1.address);
  //   const investor2BalanceAfter = await ethers.provider.getBalance(investor2.address);
  //
  //   expect(investor1BalanceAfter - investor1BalanceBefore).to.equal(ethers.parseEther("50"));
  //   expect(investor2BalanceAfter - investor2BalanceBefore).to.equal(ethers.parseEther("50"));
  //
  //   // TODO: Expect the remaining pool amount to be zero
  // });
  //
  // it("should allow paying off the debt", async function () {
  //   const amount = ethers.parseEther("100");
  //   const interestRate = 1000; // 10%
  //   const term = 9; // 9 months
  //   const investmentAmount = ethers.parseEther("25");
  //
  //   await debtLogicContract.createDebt(amount, interestRate, term, walletAddress.address, investmentAmount, tokenURI);
  //
  //   await debtLogicContract.connect(investor1).addDeposit(1, { value: ethers.parseEther("50") });
  //   await debtLogicContract.connect(investor2).addDeposit(1, { value: ethers.parseEther("50") });
  //
  //   await debtLogicContract.disburseLoan(1);
  //
  //   const walletBalanceBefore = await ethers.provider.getBalance(walletAddress.address);
  //
  //   const interestAccrued = await debtLogicContract.calculateInterest(1);
  //   const totalPayment = amount + interestAccrued;
  //
  //   await debtLogicContract.connect(investor1).payOffDebt(1, { value: totalPayment });
  //
  //   const walletBalanceAfter = await ethers.provider.getBalance(walletAddress.address);
  //
  //   expect(walletBalanceAfter - walletBalanceBefore).to.equal(totalPayment);
  //
  //   const debt = await debtLogicContract.debts(1);
  //   expect(debt.disbursed).to.equal(false);
  // });
  //
  // it("should allow NFT owner to withdraw deposit after paying off the debt", async function () {
  //   const amount = ethers.parseEther("100");
  //   const interestRate = 1000; // 10%
  //   const term = 9; // 9 months
  //   const investmentAmount = ethers.parseEther("25");
  //
  //   await debtLogicContract.createDebt(amount, interestRate, term, walletAddress.address, investmentAmount, tokenURI);
  //
  //   const debtNFTAddress = await debtLogicContract.debts(1).then((debt) => debt.nftContractAddress);
  //   debtNFT = await ethers.getContractAt("DebtNFT", debtNFTAddress);
  //
  //   await debtLogicContract.connect(investor1).addDeposit(1, { value: ethers.parseEther("50") });
  //   await debtLogicContract.connect(investor2).addDeposit(1, { value: ethers.parseEther("50") });
  //
  //   expect(await debtNFT.ownerOf(0)).to.equal(investor1.address);
  //   expect(await debtNFT.ownerOf(1)).to.equal(investor2.address);
  //
  //   await debtLogicContract.disburseLoan(1);
  //
  //   const interestAccrued = await debtLogicContract.calculateInterest(1);
  //   const totalPayment = BigInt(amount) * BigInt(10) + BigInt(interestAccrued);
  //
  //   // Send additional funds to the contract to cover the withdrawal
  //   await ethers.provider.send("hardhat_setBalance", [
  //     debtLogicContract.runner.address,
  //     ethers.toBeHex(totalPayment),
  //   ]);
  //
  //   const oldBalance = await ethers.provider.getBalance(debtLogicContract.runner.address);
  //
  //   await debtLogicContract.connect(investor1).payOffDebt(1, { value: totalPayment });
  //
  //   const investor1BalanceBefore = await ethers.provider.getBalance(investor1.address);
  //
  //   await debtLogicContract.connect(investor1).withdrawDeposit(1, 0);
  //
  //   const investor1BalanceAfter = await ethers.provider.getBalance(investor1.address);
  //
  //   expect(investor1BalanceAfter - investor1BalanceBefore).to.be.closeTo(investmentAmount + interestAccrued / BigInt(2), ethers.parseEther("0.01"));
  //
  //   await expect(debtNFT.ownerOf(0)).to.be.reverted;
  // });
});