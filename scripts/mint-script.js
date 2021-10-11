const hre = require("hardhat");
var Web3 = require('web3');
// var web3 = new Web3(Web3.givenProvider || "ws://localhost:8545");

async function main() {
  const NFT = await hre.ethers.getContractFactory("DankMinter");
  const CONTRACT_ADDRESS = "0xcfeb869f69431e42cdb54a4f4f105c19c080a601";
  const OWNER_ADDRESS = "0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1";
  const memeMachine = NFT.attach(CONTRACT_ADDRESS);
  const web3 = new Web3('http://127.0.0.1:8545');

  const templateId = 0;
  const text = ["some text", "some more text"];
  const imgHash = ethers.utils.hexZeroPad(web3.utils.asciiToHex("12345"), 32);
  const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";

  const resp = await memeMachine.createMeme(templateId, text, URI, CONTRACT_ADDRESS);
  console.log("NFT meme minted:", resp);
}

main().then(() => process.exit(0)).catch(error => {
  console.error(error);
  process.exit(1);
});