const { ethers, upgrades } = require("hardhat");

async function main() {
  const DankMinter = await ethers.getContractFactory("DankMinter");
  const TreeFiddy = await ethers.getContractFactory("TreeFiddy");

  console.log("attempting DankMinter deployment...");
  const dankMinter = await upgrades.deployProxy(DankMinter, [], {initializer: 'initialize'});
  await dankMinter.deployed();
  console.log("DankMinter deployed to:", dankMinter.address);

  console.log("attempting TreeFiddy deployment...");
  const treeFiddy = await upgrades.deployProxy(TreeFiddy, [dankMinter.address], {initializer: 'initialize'})
  await treeFiddy.deployed();
  console.log("DankMinter deployed to:", treeFiddy.address);

  console.log("setting DankMinter TreeFiddy address...");
  await dankMinter.setTreeFiddyCoinAddress(treeFiddy.address);
}

main().then(() => process.exit(0)).catch(error => {
  console.error(error);
  process.exit(1);
});
