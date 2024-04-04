const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DebtNFT", function () {
  let debtNFT;
  let owner;
  let manager;
  let regularUser;
  let debtor;

  beforeEach(async function () {
    [owner, debtor, regularUser, manager] = await ethers.getSigners();

    // Deploy DebtNFT
    const DebtNFT = await ethers.getContractFactory("DebtNFT");
    debtNFT = await DebtNFT.deploy("DEBT TOKENS", "DEBT", owner.address);

    // Grant manager role to a specific address
    const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MANAGER_ROLE"));
    await debtNFT.grantRole(MANAGER_ROLE, manager.address);
  });

  it("should mint a new NFT to a specified address", async function () {
    const tokenURI = "https://example.com/nft/1";
    await expect(debtNFT.connect(manager).mint(debtor.address, tokenURI))
      .to.emit(debtNFT, "Transfer")
      .withArgs(ethers.ZeroAddress, debtor.address, 0);

    expect(await debtNFT.tokenURI(0)).to.equal(tokenURI);
  });

  it("should prevent non-managers from minting NFTs", async function () {
    const tokenURI = "https://example.com/nft/1";
    await expect(
      debtNFT.connect(regularUser).mint(debtor.address, tokenURI)
    ).to.be.revertedWith("Caller is not a manager");
  });

  it("should allow admin to burn a token", async function () {
    const tokenURI = "https://example.com/nft/1";
    await debtNFT.connect(manager).mint(debtor.address, tokenURI);

    await expect(debtNFT.connect(owner).burn(0))
      .to.emit(debtNFT, "Transfer")
      .withArgs(debtor.address, ethers.ZeroAddress, 0);

    await expect(debtNFT.tokenURI(0)).to.be.revertedWithCustomError(
      debtNFT,
      "ERC721NonexistentToken"
    );
  });

  it("should freeze and unfreeze a token", async function () {
    const tokenURI = "https://example.com/nft/1";
    await debtNFT.connect(manager).mint(debtor.address, tokenURI);

    // Freeze the token
    await debtNFT.connect(owner).freeze(0);
    await expect(
      debtNFT
        .connect(debtor)
        .safeTransferFrom(debtor.address, regularUser.address, 0)
    ).to.be.revertedWith("DebtNFT: token is frozen");

    // Unfreeze the token
    await debtNFT.connect(owner).unfreeze(0);
    await expect(
      debtNFT
        .connect(debtor)
        .safeTransferFrom(debtor.address, regularUser.address, 0)
    )
      .to.emit(debtNFT, "Transfer")
      .withArgs(debtor.address, regularUser.address, 0);
  });

  it("should prevent non-admins from burning tokens", async function () {
    const tokenURI = "https://example.com/nft/1";
    await debtNFT.connect(manager).mint(debtor.address, tokenURI);

    await expect(debtNFT.connect(regularUser).burn(0)).to.be.revertedWith(
      "Caller is not an admin or manager"
    );
  });
});
