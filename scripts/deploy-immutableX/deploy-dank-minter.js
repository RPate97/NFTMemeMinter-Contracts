const hardhat = require('hardhat');
const { ethers } = hardhat;

/**
 * main deploys a smart contract via a call to the deploySmartContract function. To
 * use this function please ensure your environment file (.env) is configured
 * with the correct values before invoking this script.
 */
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log('Deploying Contracts with the account: ', deployer.address);
    console.log('Account Balance: ', (await deployer.getBalance()).toString());

    // Use any logic you want to determine these values
    const owner = deployer.address;
    const name = "DankMinter";
    const symbol = "MEME";

    await deploySmartContract(owner, name, symbol, hardhat.network.name);
}

/**
 * deploySmartContract compiles the solidity smart contract from the
 * contracts folder, and then deploys the contract onto one of the
 * nominated networks.
 * 
 * @param {string} owner - The address of the person that owns the contract
 * @param {string} name - Friendly name for the contract
 * @param {string} symbol - Symbol for the contract (e.g. 'GODS')
 * @param {string} network - ropsten or mainnet
 */
async function deploySmartContract(owner, name, symbol, network) {
    // Hard coded to compile and deploy the Asset.sol smart contract.
    const SmartContract = await ethers.getContractFactory(name);
    const imxAddress = getIMXAddress(network);
    // const smartContract = await SmartContract.deploy(owner, name, symbol, imxAddress);
    const smartContract = await upgrades.deployProxy(SmartContract, [owner, imxAddress, 'https://dankminter.com/api/'], {initializer: 'initialize'});

    console.log('Deployed Contract Address:', smartContract.address);
}

/**
 * Returns the IMX address for either network. DO NOT CHANGE these values.
 * @param {string} network - ropsten or mainnent
 * @returns {string} IMX address
 */
function getIMXAddress(network) {
    switch (network) {
        case 'ropsten':
            return '0x4527be8f31e2ebfbef4fcaddb5a17447b27d2aef';
        case 'mainnet':
            return '0x5FDCCA53617f4d2b9134B29090C87D01058e27e9';
        case 'dev':
            return '0x4527be8f31e2ebfbef4fcaddb5a17447b27d2aef';
    }
    throw Error('Invalid network selected');
}

main()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});