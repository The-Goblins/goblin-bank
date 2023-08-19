require("@nomicfoundation/hardhat-foundry");
import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";
import dotenv from "dotenv";
import "hardhat-contract-sizer";
import 'solidity-coverage';
dotenv.config();

const config: HardhatUserConfig = {
  networks: {
    hardhat: {
      forking: {
        url: "https://arb-mainnet.g.alchemy.com/v2/",
      },
    },
    bsctestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      accounts: [process.env.PRIVATE_KEY || ""],
    },
    bsc: {
      url: "https://bsc-dataseed.binance.org/",
      accounts: [process.env.PRIVATE_KEY || ""],
    },
    avax: {
      url: "https://api.avax.network/ext/bc/C/rpc",
      accounts: [process.env.PRIVATE_KEY || ""],
    },
  },
  solidity: {
    version: "0.8.13",
    settings: {
      optimizer: {
        enabled: true,
        runs: 100,
      },
    },
  },
  etherscan: {
    apiKey: process.env.SNOWTRACE_API_KEY || "",
  },
};

export default config;
