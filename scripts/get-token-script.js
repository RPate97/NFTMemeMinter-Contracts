const hre = require("hardhat");

async function main() {
  const NFT = await hre.ethers.getContractFactory("DankMinter");
  const CONTRACT_ADDRESS = "0xcf3A926931a32BaeC3f0af21814EAE3D1a0AEAa1"
  const contract = NFT.attach(CONTRACT_ADDRESS);

  const owner = await contract.ownerOf(1);
  console.log("Owner:", owner);
  const uri = await contract.tokenURI(1);
  console.log("URI: ", uri);
  const memeInfo = await contract.getMeme(1);
  console.log("MemeInfo: ", memeInfo);
}

main().then(() => process.exit(0)).catch(error => {
  console.error(error);
  process.exit(1);
});