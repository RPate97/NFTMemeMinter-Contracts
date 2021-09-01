const hre = require("hardhat");

async function main() {
  const NFT = await hre.ethers.getContractFactory("NFTMemeMachine");
  const CONTRACT_ADDRESS = "0x0DEBb5c9A8F81a3e16907062D7A535F9F24C7FAd"
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