const { ethers, upgrades } = require('hardhat');

async function main () {
  const DankMinterV2 = await ethers.getContractFactory('DankMinter');
  console.log('Upgrading to DankMinterV2...');
  await upgrades.upgradeProxy('0xcf3A926931a32BaeC3f0af21814EAE3D1a0AEAa1', DankMinterV2);
  console.log('DankMinterV2 upgraded');
}

main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});