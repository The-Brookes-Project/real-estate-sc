const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SmartContractLoan", function () {
  let smartContractLoan;
  let debtNFT;
  let owner;
  let investor1;
  let investor2;
  let walletAddress;
  let tokenURI = "https://verseprop-byd6bdg5exfnayd3.z02.azurefd.net/static/raven.png";
  let versepropFeeWallet;

  beforeEach(async function () {
    [owner, investor1, investor2, walletAddress, versepropFeeWallet] = await ethers.getSigners();

    const SmartContractLoan = await ethers.getContractFactory("SmartContractLoan");
    smartContractLoan = await SmartContractLoan.deploy(versepropFeeWallet);
  });

  it("should create a new debt", async function () {
    const amount = ethers.parseEther("1000000");
    const interestRate = 1000; // 10%
    const term = 9; // 9 months
    const investmentAmount = ethers.parseEther("25000");

    await smartContractLoan.createDebt(amount, interestRate, term, walletAddress.address, investmentAmount, tokenURI);
    const debt = await smartContractLoan.debts(1);

    expect(debt.amount).to.equal(amount);
    expect(debt.interestRate).to.equal(interestRate);
    expect(debt.term).to.equal(term);
    expect(debt.walletAddress).to.equal(walletAddress.address);
    expect(debt.investmentAmount).to.equal(investmentAmount);
    expect(debt.totalInvestment).to.equal(0);
    expect(debt.disbursed).to.equal(false);
    expect(debt.tokenURI).to.equal(tokenURI);
  });

  it("should allow investors to add deposits", async function () {
    const amount = ethers.parseEther("100");
    const interestRate = 1000; // 10%
    const term = 9; // 9 months
    const investmentAmount = ethers.parseEther("25");

    await smartContractLoan.createDebt(amount, interestRate, term, walletAddress.address, investmentAmount, tokenURI);

    await smartContractLoan.connect(investor1).addDeposit(1, { value: ethers.parseEther("50") });
    await smartContractLoan.connect(investor2).addDeposit(1, { value: ethers.parseEther("50") });

    const debt = await smartContractLoan.debts(1);
    expect(debt.totalInvestment).to.equal(amount);
    expect(await smartContractLoan.investments(1, investor1.address)).to.equal(ethers.parseEther("50"));
    expect(await smartContractLoan.investments(1, investor2.address)).to.equal(ethers.parseEther("50"));
  });

  it("should disburse the loan when the investment goal is reached", async function () {
    const amount = ethers.parseEther("100");
    const interestRate = 1000; // 10%
    const term = 9; // 9 months
    const investmentAmount = ethers.parseEther("25");

    await smartContractLoan.createDebt(amount, interestRate, term, walletAddress.address, investmentAmount, tokenURI);

    await smartContractLoan.connect(investor1).addDeposit(1, { value: ethers.parseEther("50") });
    await smartContractLoan.connect(investor2).addDeposit(1, { value: ethers.parseEther("50") });

    const walletBalanceBefore = await ethers.provider.getBalance(walletAddress.address);
    await smartContractLoan.disburseLoan(1);
    const walletBalanceAfter = await ethers.provider.getBalance(walletAddress.address);

    const verseProFee = amount * BigInt(2) / BigInt(100);
    const loanAmount = amount - verseProFee;

    expect(walletBalanceAfter - walletBalanceBefore).to.equal(loanAmount);

    const debt = await smartContractLoan.debts(1);
    expect(debt.disbursed).to.equal(true);
  });

  it("should return deposits if the loan is not disbursed", async function () {
    const amount = ethers.parseEther("100");
    const interestRate = 1000; // 10%
    const term = 9; // 9 months
    const investmentAmount = ethers.parseEther("25");

    await smartContractLoan.createDebt(amount, interestRate, term, walletAddress.address, investmentAmount, tokenURI);

    await smartContractLoan.connect(investor1).addDeposit(1, { value: ethers.parseEther("50") });
    await smartContractLoan.connect(investor2).addDeposit(1, { value: ethers.parseEther("50") });

    const investor1BalanceBefore = await ethers.provider.getBalance(investor1.address);
    const investor2BalanceBefore = await ethers.provider.getBalance(investor2.address);

    await smartContractLoan.returnDeposit(1);

    const investor1BalanceAfter = await ethers.provider.getBalance(investor1.address);
    const investor2BalanceAfter = await ethers.provider.getBalance(investor2.address);

    expect(investor1BalanceAfter - investor1BalanceBefore).to.equal(ethers.parseEther("50"));
    expect(investor2BalanceAfter - investor2BalanceBefore).to.equal(ethers.parseEther("50"));

    // TODO: Expect the remaining pool amount to be zero
  });

  it("should allow paying off the debt", async function () {
    const amount = ethers.parseEther("100");
    const interestRate = 1000; // 10%
    const term = 9; // 9 months
    const investmentAmount = ethers.parseEther("25");

    await smartContractLoan.createDebt(amount, interestRate, term, walletAddress.address, investmentAmount, tokenURI);

    await smartContractLoan.connect(investor1).addDeposit(1, { value: ethers.parseEther("50") });
    await smartContractLoan.connect(investor2).addDeposit(1, { value: ethers.parseEther("50") });

    await smartContractLoan.disburseLoan(1);

    const walletBalanceBefore = await ethers.provider.getBalance(walletAddress.address);

    const interestAccrued = await smartContractLoan.calculateInterest(1);
    const totalPayment = amount + interestAccrued;

    await smartContractLoan.connect(investor1).payOffDebt(1, { value: totalPayment });

    const walletBalanceAfter = await ethers.provider.getBalance(walletAddress.address);

    expect(walletBalanceAfter - walletBalanceBefore).to.equal(totalPayment);

    const debt = await smartContractLoan.debts(1);
    expect(debt.disbursed).to.equal(false);
  });

  it("should allow NFT owner to withdraw deposit after paying off the debt", async function () {
    const amount = ethers.parseEther("100");
    const interestRate = 1000; // 10%
    const term = 9; // 9 months
    const investmentAmount = ethers.parseEther("25");

    await smartContractLoan.createDebt(amount, interestRate, term, walletAddress.address, investmentAmount, tokenURI);

    const debtNFTAddress = await smartContractLoan.debts(1).then((debt) => debt.nftContractAddress);
    debtNFT = await ethers.getContractAt("DebtNFT", debtNFTAddress);

    await smartContractLoan.connect(investor1).addDeposit(1, { value: ethers.parseEther("50") });
    await smartContractLoan.connect(investor2).addDeposit(1, { value: ethers.parseEther("50") });

    expect(await debtNFT.ownerOf(0)).to.equal(investor1.address);
    expect(await debtNFT.ownerOf(1)).to.equal(investor2.address);

    await smartContractLoan.disburseLoan(1);

    const interestAccrued = await smartContractLoan.calculateInterest(1);
    const totalPayment = BigInt(amount) * BigInt(10) + BigInt(interestAccrued);

    // Send additional funds to the contract to cover the withdrawal
    await ethers.provider.send("hardhat_setBalance", [
      smartContractLoan.runner.address,
      ethers.toBeHex(totalPayment),
    ]);

    const oldBalance = await ethers.provider.getBalance(smartContractLoan.runner.address);

    await smartContractLoan.connect(investor1).payOffDebt(1, { value: totalPayment });

    const investor1BalanceBefore = await ethers.provider.getBalance(investor1.address);

    await smartContractLoan.connect(investor1).withdrawDeposit(1, 0);

    const investor1BalanceAfter = await ethers.provider.getBalance(investor1.address);

    expect(investor1BalanceAfter - investor1BalanceBefore).to.be.closeTo(investmentAmount + interestAccrued / BigInt(2), ethers.parseEther("0.01"));

    await expect(debtNFT.ownerOf(0)).to.be.reverted;
  });
});