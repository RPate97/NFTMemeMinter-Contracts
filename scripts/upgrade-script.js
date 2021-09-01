const { ethers, upgrades } = require('hardhat');

async function main () {
  const NFTMemeMachine = await ethers.getContractFactory('NFTMemeMachine');
  console.log('Upgrading MemeMachine...');
  await upgrades.upgradeProxy('0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0', NFTMemeMachine);
  console.log('MemeMachine upgraded');
}

main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});