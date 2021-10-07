const { ethers, upgrades } = require("hardhat");

async function main() {
  const MemeMinter = await ethers.getContractFactory("DankMinter");
  const memeMinter = await upgrades.deployProxy(MemeMinter, [], {initializer: 'initialize'});
  await memeMinter.deployed();
  console.log("DankMinter deployed to:", memeMinter.address);
}

main().then(() => process.exit(0)).catch(error => {
  console.error(error);
  process.exit(1);
});
