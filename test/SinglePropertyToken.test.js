const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SinglePropertyToken", function () {
  let singlePropertyToken;
  let owner;
  let manager;
  let investor1;
  let investor2;

  const tokenName = "Demo Property Token";
  const tokenSymbol = "DPT";
  const maxSupply = 100;

  const defaultPropertyDetails = {
    assetType: 1, // EQUITY
    assetValuation: ethers.parseEther("1000000"),
    investorType: 0, // PUBLIC
    kycRequired: true,
    payoutType: 1, // FIXED_INTEREST
    payoutFrequency: 1, // QUARTERLY
    yieldRate: 800, // 8% in basis points
    hasVotingRights: false,
    votingThreshold: 0,
    propertyURI: "ipfs://QmDemo123"
  };

  beforeEach(async function () {
    [owner, manager, investor1, investor2] = await ethers.getSigners();

    const SinglePropertyToken = await ethers.getContractFactory("SinglePropertyToken");
    singlePropertyToken = await SinglePropertyToken.deploy(
      tokenName,
      tokenSymbol,
      maxSupply,
      defaultPropertyDetails
    );
  });

  describe("Deployment", function () {
    it("should deploy contract with correct name and symbol", async function () {
      expect(await singlePropertyToken.name()).to.equal(tokenName);
      expect(await singlePropertyToken.symbol()).to.equal(tokenSymbol);
    });

    it("should set correct property details on deployment", async function () {
      const details = await singlePropertyToken.propertyDetails();
      expect(details.yieldRate).to.equal(800);
      expect(details.assetValuation).to.equal(ethers.parseEther("1000000"));
      expect(details.kycRequired).to.equal(true);
    });

    it("should grant MANAGER_ROLE to deployer", async function () {
      const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MANAGER_ROLE"));
      expect(await singlePropertyToken.hasRole(MANAGER_ROLE, owner.address)).to.be.true;
    });
  });

  describe("mint", function () {
    it("should mint token with correct token ID to investor", async function () {
      await singlePropertyToken.mint(investor1.address);

      expect(await singlePropertyToken.ownerOf(1)).to.equal(investor1.address);
      expect(await singlePropertyToken.totalSupply()).to.equal(1);
    });

    it("should fail when non-manager tries to mint", async function () {
      await expect(
        singlePropertyToken.connect(investor1).mint(investor2.address)
      ).to.be.reverted;
    });
  });

  describe("recordPayment", function () {
    beforeEach(async function () {
      await singlePropertyToken.mint(investor1.address);
    });

    it("should record payment and update dividend tracking", async function () {
      const paymentAmount = ethers.parseEther("100");
      const paymentId = "DIV-2024-001";

      await singlePropertyToken.recordPayment(1, paymentAmount, paymentId);

      const totalPayments = await singlePropertyToken.totalPaymentsByToken(1);
      expect(totalPayments).to.equal(paymentAmount);

      const payments = await singlePropertyToken.getPaymentsByToken(1);
      expect(payments.length).to.equal(1);
      expect(payments[0].amount).to.equal(paymentAmount);
      expect(payments[0].paymentId).to.equal(paymentId);
    });

    it("should emit PaymentRecorded event with correct args", async function () {
      const paymentAmount = ethers.parseEther("50");
      const paymentId = "DIV-2024-002";

      const tx = await singlePropertyToken.recordPayment(1, paymentAmount, paymentId);
      const receipt = await tx.wait();
      const block = await ethers.provider.getBlock(receipt.blockNumber);

      await expect(tx)
        .to.emit(singlePropertyToken, "PaymentRecorded")
        .withArgs(investor1.address, 1, paymentAmount, paymentId, block.timestamp);
    });
  });

  describe("burn", function () {
    beforeEach(async function () {
      await singlePropertyToken.mint(investor1.address);
    });

    it("should burn token when called by owner", async function () {
      await singlePropertyToken.connect(investor1).burn(1);

      expect(await singlePropertyToken.totalSupply()).to.equal(0);
      await expect(singlePropertyToken.ownerOf(1)).to.be.reverted;
    });

    it("should fail when non-owner tries to burn", async function () {
      await expect(
        singlePropertyToken.connect(investor2).burn(1)
      ).to.be.revertedWith("Caller is not owner nor approved");
    });
  });
});
