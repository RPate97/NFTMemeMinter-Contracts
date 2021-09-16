const hre = require("hardhat");

async function main() {
  const MemeMinter = await ethers.getContractFactory("MemeMinter");
  const memeMinter = await upgrades.deployProxy(MemeMinter, [], {initializer: 'initialize'});
  await memeMinter.deployed();
  console.log("MemeMinterV2 deployed to:", memeMinter.address);
}

main().then(() => process.exit(0)).catch(error => {
  console.error(error);
  process.exit(1);
});
