const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const { Currency, DebtStatus } = require("./utils");
const { int } = require("hardhat/internal/core/params/argumentTypes");

describe("debtLogicContract", function () {
  let debtLogic;
  let debtLogicAddr;
  let debtStorage;
  let debtNFT;
  let owner;
  let investor1;
  let investor2;
  let walletAddress;
  let tokenURI =
    "https://verseprop-byd6bdg5exfnayd3.z02.azurefd.net/static/raven.png";
  let usdcTokenAddress = "0x036CbD53842c5426634e7929541eC2318f3dCF7e";
  let versepropFeeWallet;

  beforeEach(async function () {
    [owner, investor1, investor2, walletAddress, versepropFeeWallet] =
      await ethers.getSigners();

    // Deploy DebtStorage
    const DebtStorage = await ethers.getContractFactory("DebtStorage");
    debtStorage = await DebtStorage.deploy(
      owner.address,
      versepropFeeWallet.address,
      usdcTokenAddress
    );
    const storageContractAddress = await debtStorage.getAddress();

    // Deploy DebtLogic with the address of DebtStorage
    const DebtLogic = await ethers.getContractFactory("DebtLogic");
    debtLogic = await upgrades.deployProxy(
      DebtLogic,
      [storageContractAddress],
      {
        initializer: "initialize",
      }
    );

    debtLogicAddr = await debtLogic.getAddress();
    const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MANAGER_ROLE"));
    await debtStorage.grantRole(MANAGER_ROLE, debtLogicAddr);
  });

  it("should create a new debt", async function () {
    const debtId = await debtStorage.debtCount();
    const amount = ethers.parseEther("100");
    const interestRate = 1000; // 10%
    const term = 9; // 9 months
    const investmentAmount = ethers.parseEther("2");

    await debtLogic.createDebt(
      amount,
      interestRate,
      term,
      walletAddress.address,
      investmentAmount,
      tokenURI,
      Currency.ETH
    );

    const debt = await debtStorage.getDebt(debtId);
    expect(debt[0].toString()).to.equal(amount.toString());
    expect(debt[1]).to.equal(interestRate);
    expect(debt[2]).to.equal(term);
    expect(debt[3]).to.equal(walletAddress.address);
    expect(debt[4].toString()).to.equal(investmentAmount.toString());
    expect(debt[5]).to.equal(0);
    expect(debt[10]).to.equal(tokenURI);
    expect(debt[11]).to.equal(0);
  });

  it("should allow investors to add deposits", async function () {
    const amount = ethers.parseEther("100");
    const interestRate = 1000; // 10%
    const term = 9; // 9 months
    const investmentAmount = ethers.parseEther("2");

    await debtLogic.createDebt(
      amount,
      interestRate,
      term,
      walletAddress.address,
      investmentAmount,
      tokenURI,
      Currency.ETH
    );

    await debtLogic
      .connect(investor1)
      .addDeposit(0, ethers.parseEther("3"), { value: ethers.parseEther("3") });
    await debtLogic
      .connect(investor2)
      .addDeposit(0, ethers.parseEther("2"), { value: ethers.parseEther("2") });

    const debt = await debtStorage.debts(0);
    expect(debt.totalInvestment).to.equal(ethers.parseEther("5"));

    expect(await debtStorage.investments(0, 0)).to.equal(
      ethers.parseEther("3")
    );

    expect(await debtStorage.investments(0, 1)).to.equal(
      ethers.parseEther("2")
    );
  });

  it("should disburse the loan when the investment goal is reached", async function () {
    const amount = ethers.parseEther("5");
    const interestRate = 1000; // 10%
    const term = 9; // 9 months
    const investmentAmount = ethers.parseEther("2");

    await debtLogic.createDebt(
      amount,
      interestRate,
      term,
      walletAddress.address,
      investmentAmount,
      tokenURI,
      Currency.ETH
    );

    await debtLogic
      .connect(investor1)
      .addDeposit(0, ethers.parseEther("3"), { value: ethers.parseEther("3") });

    await debtLogic
      .connect(investor2)
      .addDeposit(0, ethers.parseEther("2"), { value: ethers.parseEther("2") });

    const walletBalanceBefore = await ethers.provider.getBalance(
      walletAddress.address
    );
    await debtLogic.disburseLoan(0);
    const walletBalanceAfter = await ethers.provider.getBalance(
      walletAddress.address
    );

    const verseProFee = (amount * BigInt(2)) / BigInt(100);
    const loanAmount = amount - verseProFee;

    expect(walletBalanceAfter - walletBalanceBefore).to.equal(loanAmount);

    const debt = await debtStorage.debts(0);
    expect(debt[6]).to.equal(DebtStatus.FUNDED);
  });

  it("should return deposits if the loan is not disbursed", async function () {
    const amount = ethers.parseEther("100");
    const interestRate = 1000; // 10%
    const term = 9; // 9 months
    const investmentAmount = ethers.parseEther("2");

    await debtLogic.createDebt(
      amount,
      interestRate,
      term,
      walletAddress.address,
      investmentAmount,
      tokenURI,
      Currency.ETH
    );

    await debtLogic
      .connect(investor1)
      .addDeposit(0, ethers.parseEther("3"), { value: ethers.parseEther("3") });
    await debtLogic
      .connect(investor2)
      .addDeposit(0, ethers.parseEther("2"), { value: ethers.parseEther("2") });

    const investor1BalanceBefore = await ethers.provider.getBalance(
      investor1.address
    );
    const investor2BalanceBefore = await ethers.provider.getBalance(
      investor2.address
    );

    await debtLogic.connect(owner).returnDeposit(0);

    const investor1BalanceAfter = await ethers.provider.getBalance(
      investor1.address
    );
    const investor2BalanceAfter = await ethers.provider.getBalance(
      investor2.address
    );

    expect(investor1BalanceAfter - investor1BalanceBefore).to.equal(
      ethers.parseEther("3")
    );
    expect(investor2BalanceAfter - investor2BalanceBefore).to.equal(
      ethers.parseEther("2")
    );
  });

  it("should allow paying off the debt", async function () {
    const amount = ethers.parseEther("10");
    const interestRate = 1000; // 10%
    const term = 9; // 9 months
    const investmentAmount = ethers.parseEther("2");

    await debtLogic.createDebt(
      amount,
      interestRate,
      term,
      walletAddress.address,
      investmentAmount,
      tokenURI,
      Currency.ETH
    );

    await debtLogic
      .connect(investor1)
      .addDeposit(0, ethers.parseEther("7"), { value: ethers.parseEther("7") });
    await debtLogic
      .connect(investor2)
      .addDeposit(0, ethers.parseEther("3"), { value: ethers.parseEther("3") });

    await debtLogic.disburseLoan(0);

    const walletBalanceBefore = await ethers.provider.getBalance(
      walletAddress.address
    );

    const interestAccrued = await debtLogic.calculateInterest(0, amount);
    const totalPayment = amount + interestAccrued;

    await debtLogic.connect(investor1).payOffDebt(0, { value: totalPayment });

    const walletBalanceAfter = await ethers.provider.getBalance(
      walletAddress.address
    );
    const contractBalance = await ethers.provider.getBalance(debtLogicAddr);
    expect(contractBalance).to.equal(totalPayment);
    expect(walletBalanceAfter - walletBalanceBefore).to.equal(0);

    const debt = await debtStorage.debts(0);
    expect(debt[6]).to.equal(DebtStatus.SETTLED);
  });

  it("should allow NFT owner to withdraw deposit after paying off the debt", async function () {
    const contractAddress = await debtLogic.getAddress();
    const amount = ethers.parseEther("10");
    const interestRate = 1000; // 10%
    const term = 9; // 9 months
    const investmentAmount = ethers.parseEther("2");

    await debtLogic.createDebt(
      amount,
      interestRate,
      term,
      walletAddress.address,
      investmentAmount,
      tokenURI,
      Currency.ETH
    );

    const debtNFTAddress = await debtStorage
      .debts(0)
      .then((debt) => debt.nftContractAddress);
    debtNFT = await ethers.getContractAt("DebtNFT", debtNFTAddress);

    await debtLogic
      .connect(investor1)
      .addDeposit(0, ethers.parseEther("7"), { value: ethers.parseEther("7") });
    await debtLogic
      .connect(investor2)
      .addDeposit(0, ethers.parseEther("3"), { value: ethers.parseEther("3") });

    expect(await debtNFT.ownerOf(0)).to.equal(investor1.address);
    expect(await debtNFT.ownerOf(1)).to.equal(investor2.address);

    await debtLogic.disburseLoan(0);

    const interestAccrued = await debtLogic.calculateInterest(0, amount);
    const totalPayment = amount + interestAccrued;

    await debtLogic.connect(investor1).payOffDebt(0, { value: totalPayment });

    const investor1BalanceBefore = await ethers.provider.getBalance(
      investor1.address
    );

    const investor2BalanceBefore = await ethers.provider.getBalance(
      investor2.address
    );

    await debtLogic.connect(investor1).withdrawDeposit(0, 0);
    await debtLogic.connect(investor2).withdrawDeposit(0, 1);

    const investor1BalanceAfter = await ethers.provider.getBalance(
      investor1.address
    );
    const investor2BalanceAfter = await ethers.provider.getBalance(
      investor2.address
    );

    // Account for gas discrepancy
    expect(investor1BalanceAfter - investor1BalanceBefore).to.be.closeTo(
      ethers.parseEther("7") + interestAccrued,
      ethers.parseEther("0.01")
    );

    expect(investor2BalanceAfter - investor2BalanceBefore).to.be.closeTo(
      ethers.parseEther("3") + interestAccrued,
      ethers.parseEther("0.01")
    );

    await expect(debtNFT.ownerOf(0)).to.be.reverted;
    await expect(debtNFT.ownerOf(1)).to.be.reverted;
  });
});
