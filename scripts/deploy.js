const { ethers } = require("hardhat");

async function main() {
  const [owner] = await ethers.getSigners();
  const versepropFeeWallet = "0xb3102C64373A065582f8208C856Cf43199C14D76";
  const usdcTokenAddress = "0x036CbD53842c5426634e7929541eC2318f3dCF7e";

  // Deploy the DebtStorage contract
  const DebtStorage = await ethers.getContractFactory("DebtStorage");
  const debtStorage = await DebtStorage.deploy(
    owner.address,
    versepropFeeWallet,
    usdcTokenAddress
  );
  const storageContractAddress = await debtStorage.getAddress();
  console.log("Storage Contract Deployed to: ", storageContractAddress);

  // Deploy DebtLogic with the address of DebtStorage
  const DebtLogic = await ethers.getContractFactory("DebtLogic");
  const debtLogic = await upgrades.deployProxy(
    DebtLogic,
    [storageContractAddress],
    { initializer: "initialize" }
  );

  const debtLogicAddr = await debtLogic.getAddress();
  console.log('Logic Contract Deployed to: ', debtLogicAddr);
  const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MANAGER_ROLE"));
  await debtStorage.grantRole(MANAGER_ROLE, debtLogicAddr);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });