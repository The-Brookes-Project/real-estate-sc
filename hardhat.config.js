require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("@babel/register");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  mocha: {
    require: ["@babel/register"]
  },
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
    viaIR: true
  }
};
