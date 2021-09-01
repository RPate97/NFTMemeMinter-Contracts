const hre = require("hardhat");
var Web3 = require('web3');
var web3 = new Web3(Web3.givenProvider || "ws://localhost:8545");

async function main() {
  const NFT = await hre.ethers.getContractFactory("NFTMemeMachine");
  const CONTRACT_ADDRESS = "0x6C305ACa67eF70De7f0ac4f588D39CEe47334D88";
  const memeMachine = NFT.attach(CONTRACT_ADDRESS);

  const templateId = 42069;
  const text = ["Stealing memes to repost", "Making dank memes", "Watermarking your dank memes", "Minting nfts of your dank memes"];
  const imgHash = ethers.utils.hexZeroPad(web3.utils.asciiToHex("42069"), 32);
  const URI = "https://gateway.pinata.cloud/ipfs/QmPtKsbdZk59qcpoW5V47C78mZCYqiFJE5FgJHVsJApWd8"

  // whitelist uri
  await memeMachine.addWhitelistedMemeURI(URI, templateId, text);
  // create meme
  await memeMachine.createMeme(templateId, text, imgHash, URI);
  console.log("NFT meme minted:", memeMachine);
}

main().then(() => process.exit(0)).catch(error => {
  console.error(error);
  process.exit(1);
});