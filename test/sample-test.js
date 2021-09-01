// const { expect } = require("chai");
// const { ethersm, upgrades } = require("hardhat");
// const { accounts, contract } = require("@openzeppelin/test-environment");

// describe("NFTMemeMachine", function() {
//   // beforeEach(async function() {
//   //   this.meme = await NFTMemeMachine.new({ from: owner });
//   //   await this.meme.initialize(owner);
//   // })

//   // it("the deployer is the owner", async function() {
//   //   const NFTMemeMachine = await ethers.getContractFactory("NFTMemeMachine");
//   //   const [owner] = accounts;
//   //   const meme = await upgrades.deployProxy(NFTMemeMachine);
//   //   await meme.initialize(owner);
//   //   await meme.deployed()
//   //   expect(await this.meme.owner()).to.equal(owner);
//   // });

//   // it("It should deploy the contract, whitelist a uri, mint a token, and resolve to the right URI", async function() {
//   //   const NFTMemeMachine = await ethers.getContractFactory("NFTMemeMachine");
//   //   const meme = await NFTMemeMachine.deploy();
//   //   // meme info
//   //   const templateId = 0;
//   //   const text = ["some text", "some more text"];
//   //   const imgHash = 12345;
//   //   const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";
//   //   // check deployed
//   //   await meme.deployed();
//   //   // whitelist uri
//   //   await meme.addWhitelistedMemeURI(URI, templateId, text);
//   //   // create meme
//   //   await meme.createMeme(templateId, text, imgHash, URI);
//   //   expect(await meme.tokenURI(1)).to.equal(URI);
//   // });
// });
