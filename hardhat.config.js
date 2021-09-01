require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require('@openzeppelin/hardhat-upgrades');
require("solidity-coverage");
require("hardhat-gas-reporter");
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
    matic: {
      url: "https://matic-mumbai.chainstacklabs.com",
      accounts: [PRIVATE_KEY],
      gasPrice: 8000000000, 
    }
  },
  solidity: {
    version: "0.8.2",
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
  }
}