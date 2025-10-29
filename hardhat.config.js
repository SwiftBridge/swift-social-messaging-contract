require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

// Validate private key format
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const accounts = PRIVATE_KEY && PRIVATE_KEY.startsWith('0x') && PRIVATE_KEY.length === 66
  ? [PRIVATE_KEY]
  : [];

module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    base: {
      url: process.env.BASE_MAINNET_RPC_URL || "https://mainnet.base.org",
      accounts: accounts,
      chainId: 8453,
    },
    "base-sepolia": {
      url: "https://sepolia.base.org",
      accounts: accounts,
      chainId: 84532,
    },
  },
  etherscan: {
    apiKey: process.env.BASESCAN_API_KEY || "",
    customChains: [
      {
        network: "base",
        chainId: 8453,
        urls: {
          apiURL: "https://api.basescan.org/api",
          browserURL: "https://basescan.org"
        }
      }
    ]
  },
  sourcify: {
    enabled: false
  }
};
