const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying SinglePropertyToken with account:", deployer.address);

  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance), "ETH");

  // Demo property configuration
  const tokenName = "VerseProp Demo Property";
  const tokenSymbol = "VPDEMO";
  const maxSupply = 1000;

  const propertyDetails = {
    assetType: 1, // EQUITY
    assetValuation: ethers.parseEther("500000"), // $500,000 valuation
    investorType: 0, // PUBLIC
    kycRequired: true,
    payoutType: 1, // FIXED_INTEREST
    payoutFrequency: 1, // QUARTERLY
    yieldRate: 800, // 8% annual yield in basis points
    hasVotingRights: false,
    votingThreshold: 0,
    propertyURI: "ipfs://QmDemoPropertyMetadata"
  };

  console.log("\nDeploying SinglePropertyToken...");
  console.log("Token Name:", tokenName);
  console.log("Token Symbol:", tokenSymbol);
  console.log("Max Supply:", maxSupply);
  console.log("Yield Rate:", propertyDetails.yieldRate / 100 + "%");

  const SinglePropertyToken = await ethers.getContractFactory("SinglePropertyToken");
  const singlePropertyToken = await SinglePropertyToken.deploy(
    tokenName,
    tokenSymbol,
    maxSupply,
    propertyDetails
  );

  await singlePropertyToken.waitForDeployment();
  const contractAddress = await singlePropertyToken.getAddress();

  console.log("\n=== Deployment Successful ===");
  console.log("Contract Address:", contractAddress);
  console.log("Network:", (await ethers.provider.getNetwork()).name);
  console.log("Chain ID:", (await ethers.provider.getNetwork()).chainId.toString());

  // Verify MANAGER_ROLE is set for deployer
  const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MANAGER_ROLE"));
  const hasManagerRole = await singlePropertyToken.hasRole(MANAGER_ROLE, deployer.address);
  console.log("\nDeployer has MANAGER_ROLE:", hasManagerRole);

  // If a platform wallet is configured, grant MANAGER_ROLE
  if (process.env.PLATFORM_WALLET_ADDRESS) {
    console.log("\nGranting MANAGER_ROLE to platform wallet:", process.env.PLATFORM_WALLET_ADDRESS);
    await singlePropertyToken.grantRole(MANAGER_ROLE, process.env.PLATFORM_WALLET_ADDRESS);
    console.log("MANAGER_ROLE granted successfully");
  }

  console.log("\n=== Configuration for Backend ===");
  console.log("DEMO_CONTRACT_ADDRESS=" + contractAddress);

  // Get the explorer URL based on chain ID
  const chainId = (await ethers.provider.getNetwork()).chainId;
  let explorerUrl;
  if (chainId === 43113n) {
    explorerUrl = "https://testnet.snowtrace.io/address/" + contractAddress;
  } else if (chainId === 421614n) {
    explorerUrl = "https://sepolia.arbiscan.io/address/" + contractAddress;
  } else {
    explorerUrl = "Contract deployed at: " + contractAddress;
  }
  console.log("\nView on Explorer:", explorerUrl);

  return contractAddress;
}

main()
  .then((address) => {
    console.log("\nDeployment complete. Contract address:", address);
    process.exit(0);
  })
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  });
