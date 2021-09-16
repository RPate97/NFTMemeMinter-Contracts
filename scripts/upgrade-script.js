const { ethers, upgrades } = require('hardhat');

async function main () {
  const MemeMinterV2 = await ethers.getContractFactory('MemeMinterV2');
  console.log('Upgrading to MemeMinterV2...');
  await upgrades.upgradeProxy('0xcf3A926931a32BaeC3f0af21814EAE3D1a0AEAa1', MemeMinterV2);
  console.log('MemeMinterV2 upgraded');
}

main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});