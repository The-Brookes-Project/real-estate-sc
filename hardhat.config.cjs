require("@nomicfoundation/hardhat-toolbox");
require("@babel/register");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  mocha: {
    require: ["@babel/register"]
  }
};
