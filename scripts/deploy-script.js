const hre = require("hardhat");

async function main() {
  const NFTMemeMachine = await ethers.getContractFactory("NFTMemeMachine");
  const memeMachine = await upgrades.deployProxy(NFTMemeMachine, [], {initializer: 'initialize'});
  await memeMachine.deployed();
  console.log("NFTMemeMachine deployed to:", memeMachine.address);
}

main().then(() => process.exit(0)).catch(error => {
  console.error(error);
  process.exit(1);
});
