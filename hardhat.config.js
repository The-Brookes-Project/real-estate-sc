require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("@babel/register");
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      }
    },
  },
  mocha: {
    require: ["@babel/register"]
  },
  networks: {
    // for mainnet
    'base-mainnet': {
      url: 'https://mainnet.base.org',
      accounts: [process.env.WALLET_KEY],
      gasPrice: 1000000000,
    },
    // for testnet
    'base-sepolia': {
      url: 'https://sepolia.base.org',
      accounts: [process.env.WALLET_KEY],
      gasPrice: 1000000000,
    },
    // for local dev environment
    'base-local': {
      url: 'http://localhost:8545',
      accounts: [process.env.WALLET_KEY],
      gasPrice: 1000000000,
    },
    // Arbitrum Sepolia testnet for demo
    'arbitrum-sepolia': {
      url: process.env.ARBITRUM_SEPOLIA_RPC_URL || 'https://sepolia-rollup.arbitrum.io/rpc',
      accounts: process.env.DEMO_FAUCET_WALLET_PRIVATE_KEY
        ? [process.env.DEMO_FAUCET_WALLET_PRIVATE_KEY]
        : [process.env.WALLET_KEY],
      chainId: 421614,
    },
    // Avalanche Fuji testnet for demo
    'fuji': {
      url: process.env.AVALANCHE_FUJI_RPC_URL || 'https://api.avax-test.network/ext/bc/C/rpc',
      accounts: process.env.DEMO_FAUCET_WALLET_PRIVATE_KEY
        ? [process.env.DEMO_FAUCET_WALLET_PRIVATE_KEY]
        : [process.env.WALLET_KEY],
      chainId: 43113,
    },
  },
  etherscan: {
    apiKey: {
      'arbitrum-sepolia': process.env.ARBISCAN_API_KEY || '',
      'base-sepolia': process.env.BASESCAN_API_KEY || '',
    },
    customChains: [
      {
        network: 'arbitrum-sepolia',
        chainId: 421614,
        urls: {
          apiURL: 'https://api-sepolia.arbiscan.io/api',
          browserURL: 'https://sepolia.arbiscan.io',
        },
      },
    ],
  },
  defaultNetwork: 'hardhat',
};
