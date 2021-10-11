require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require('@openzeppelin/hardhat-upgrades');
require("solidity-coverage");
require("hardhat-gas-reporter");
require('hardhat-abi-exporter');
require('dotenv').config();
const PRIVATE_KEY = process.env.PRIVATE_KEY;

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  // defaultNetwork: "matic",
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
    },
    development: {
      url: "http://127.0.0.1:8545",
    },
    matic: {
      // url: "https://rpc-mumbai.maticvigil.com/v1/6271d1806b2b1cb80342e3190d30043d0ac58813",
      url: "https://rpc-mumbai.maticvigil.com/",
      chainId: 80001,
      accounts: [PRIVATE_KEY],
      gas: 8000000,
      gasPrice: 8000000, 
      timeout: 20000
    }
  },
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      }
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 20000
  },
  gasReporter: {
    currency: 'USD',
    gasPrice: 15,
    enabled: true,
  },
  abiExporter: {
    path: './data/abi',
    clear: true,
    flat: true,
    only: [],
    spacing: 2
  }
}