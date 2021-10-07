const { ethers, upgrades } = require("hardhat");

async function main() {
  const DankMinter = await ethers.getContractFactory("DankMinter");
  console.log(await ethers.provider.getBlockNumber());
  let dankMinter;
  let retry = true;
  while(retry) {
    try {
      console.log("attempting deployment...");
      dankMinter = await upgrades.deployProxy(DankMinter, [], {initializer: 'initialize'});
      retry = false;
    } catch (e) {
      console.log(e);
      console.log("Caught TransactionMinedTimeout, retrying...")
      retry = true;
    }    
  }

  await dankMinter.deployed();
  console.log("DankMinter deployed to:", dankMinter.address);
}

main().then(() => process.exit(0)).catch(error => {
  console.error(error);
  process.exit(1);
});
