const hre = require("hardhat");
var Web3 = require('web3');
var web3 = new Web3(Web3.givenProvider || "ws://localhost:8545");

async function main() {
  const NFT = await hre.ethers.getContractFactory("MemeMinterV2");
  const CONTRACT_ADDRESS = "0xcf3A926931a32BaeC3f0af21814EAE3D1a0AEAa1";
  const memeMachine = NFT.attach(CONTRACT_ADDRESS);

  const templateId = 0;
  const text = ["some text", "some more text"];
  const imgHash = ethers.utils.hexZeroPad(web3.utils.asciiToHex("12345"), 32);
  const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";

  // calculate meme hash
  var textStr = "";
  for (var i = 0; i < text.length; i++) {
      textStr += text[i];
  }
  const encoded = web3.eth.abi.encodeParameters(['uint256', 'string'], [templateId, textStr])
  const hash = web3.utils.sha3(encoded, {encoding: 'hex'});
  console.log("made meme hash");
  console.log(hash);
  
  // calculate uri hash
  const encodedURI = web3.eth.abi.encodeParameters(['string'], [URI]);
  const hURI = web3.utils.sha3(encodedURI, {encoding: 'hex'});
  console.log("made uri hash");
  console.log(hURI);

  // whitelist uri
  await memeMachine.addWhitelistedMemeURI(hURI, hash);
  // create meme
  await memeMachine.createMeme(templateId, text, imgHash, URI);
  console.log("NFT meme minted:", memeMachine);
}

main().then(() => process.exit(0)).catch(error => {
  console.error(error);
  process.exit(1);
});