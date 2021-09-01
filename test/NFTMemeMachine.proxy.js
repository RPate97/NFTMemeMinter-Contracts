// test/Box.proxy.js
// Load dependencies
var Web3 = require('web3');
var web3 = new Web3(Web3.givenProvider || "ws://localhost:8545");
var BN = web3.utils.BN;
var crypto = require('crypto');
const { expect } = require('chai');
 
let NFTMemeMachine;
let memeMachine;
 
// Start test block
describe('NFTMemeMachine (proxy)', function () {
  beforeEach(async function () {
    NFTMemeMachine = await ethers.getContractFactory("NFTMemeMachine");
    memeMachine = await upgrades.deployProxy(NFTMemeMachine, [], {initializer: 'initialize'});
  });
 
  it('Whitelist URI, mint a token, expect correct URI and correct hash, expect memeId to be returned using hash', async function () {
    // meme info
    const templateId = 0;
    const text = ["some text", "some more text"];
    const imgHash = ethers.utils.hexZeroPad(web3.utils.asciiToHex("12345"), 32);
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";

    // calculate hash
    var textStr = "";
    for (var i = 0; i < text.length; i++) {
        textStr += text[i];
    }
    const encoded = web3.eth.abi.encodeParameters(['uint256', 'string'], [templateId, textStr])
    const hash = web3.utils.sha3(encoded, {encoding: 'hex'});

    // whitelist uri
    await memeMachine.addWhitelistedMemeURI(URI, templateId, text);
    // create meme
    await memeMachine.createMeme(templateId, text, imgHash, URI);
    // get info
    const res = await memeMachine.getMeme(1);
    const memeHash = res[0];
    const memeImgHash = res[1];
    const memeScore = res[2];
    const memeUri = res[3];
    // expect correct info
    expect(memeHash).to.equal(hash, "meme hash is not correct");
    expect(memeImgHash).to.equal(imgHash, "img hash is not correct");
    expect(memeScore).to.equal(1, "score is not correct");
    expect(memeUri).to.equal(memeUri, "uri is not correct");
    // verify memeId returned with hash
    const res2 = await memeMachine.getMemeWithHash(hash);
    expect(res2[0]).to.equal(URI);
    expect(res2[1]).to.equal(1);
  });

  it('Whitelist two URIs, mint token, mint another token and expect revert with cooldown error', async function () {
    // meme info
    const templateId = 0;
    const text = ["some text", "some more text"];
    const imgHash = ethers.utils.hexZeroPad(web3.utils.asciiToHex("12345"), 32);
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";
    const URI2 = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv-two";

    // whitelist uris
    await memeMachine.addWhitelistedMemeURI(URI, templateId, text);
    await memeMachine.addWhitelistedMemeURI(URI2, templateId, text);
    // create meme
    await memeMachine.createMeme(templateId, text, imgHash, URI);
    // create another meme and expect revert
    await expect(memeMachine.createMeme(templateId, text, imgHash, URI2)).to.be.revertedWith("cooldown error");
  });

  it('Mint token without whitelisting, expect revert with not whitelisted error', async function () {
    // meme info
    const templateId = 0;
    const text = ["some text", "some more text"];
    const imgHash = ethers.utils.hexZeroPad(web3.utils.asciiToHex("12345"), 32);
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";

    // create another meme and expect revert
    await expect(memeMachine.createMeme(templateId, text, imgHash, URI)).to.be.revertedWith("not whitelisted error");
  });

  it('Whitelist two URIs, mint token, update creation cooldown, mint another token and expect revert with not unique', async function () {
    // meme info
    const templateId = 0;
    const text = ["some text", "some more text"];
    const imgHash = ethers.utils.hexZeroPad(web3.utils.asciiToHex("12345"), 32);
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";
    const URI2 = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv-two";
    // update cooldown
    await memeMachine.updateCreationCooldownTime(0);
    // whitelist uris
    await memeMachine.addWhitelistedMemeURI(URI, templateId, text);
    await memeMachine.addWhitelistedMemeURI(URI2, templateId, text);
    // create meme
    await memeMachine.createMeme(templateId, text, imgHash, URI);
    // create another meme and expect revert
    await expect(memeMachine.createMeme(templateId, text, imgHash, URI2)).to.be.revertedWith("not unique error");
  });

  it('Whitelist one URI, mint token, update creation cooldown, mint another token and expect revert not whitelisted error', async function () {
    // meme info
    const templateId = 0;
    const text = ["some text", "some more text"];
    const imgHash = ethers.utils.hexZeroPad(web3.utils.asciiToHex("12345"), 32);
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";
    const URI2 = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv-two";
    // update cooldown
    await memeMachine.updateCreationCooldownTime(0);
    // whitelist uris
    await memeMachine.addWhitelistedMemeURI(URI, templateId, text);
    // create meme
    await memeMachine.createMeme(templateId, text, imgHash, URI);
    // create another meme and expect revert
    await expect(memeMachine.createMeme(1, ["some unique text"], imgHash, URI2)).to.be.revertedWith("not whitelisted error");
  });

  it('Whitelist two URIs, mint token, update creation cooldown, mint another token and expect revert with not unique img error', async function () {
    // meme info
    const templateId = 0;
    const text = ["some text", "some more text"];
    const imgHash = ethers.utils.hexZeroPad(web3.utils.asciiToHex("12345"), 32);
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";
    const URI2 = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv-two";
    // update cooldown
    await memeMachine.updateCreationCooldownTime(0);
    // whitelist uris
    await memeMachine.addWhitelistedMemeURI(URI, templateId, text);
    await memeMachine.addWhitelistedMemeURI(URI2, 1, ["some unique text"]);
    // create meme
    await memeMachine.createMeme(templateId, text, imgHash, URI);
    // create another meme and expect revert
    await expect(memeMachine.createMeme(1, ["some unique text"], imgHash, URI2)).to.be.revertedWith("not unique img error");
  });

  it('Update creation cooldown time, expect correct cooldown time', async function() {
    const newCooldownTime = 0;
    await memeMachine.updateCreationCooldownTime(newCooldownTime);
    const res = await memeMachine.getCreationCooldownTime();
    expect(res).to.equal(0);
  });

  it('Mint meme and upvote it, expect correct score', async function() {
    // meme info
    const templateId = 0;
    const text = ["some text", "some more text"];
    const imgHash = ethers.utils.hexZeroPad(web3.utils.asciiToHex("12345"), 32);
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";

    // whitelist uri
    await memeMachine.addWhitelistedMemeURI(URI, templateId, text);
    // create meme
    await memeMachine.createMeme(templateId, text, imgHash, URI);
    // vote on meme
    await memeMachine.voteOnMeme(1, true);
    const res = await memeMachine.getMeme(1);
    expect(res[2]).to.equal(2);
  });

  it('Mint meme and downvote it, expect correct score', async function() {
    // meme info
    const templateId = 0;
    const text = ["some text", "some more text"];
    const imgHash = ethers.utils.hexZeroPad(web3.utils.asciiToHex("12345"), 32);
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";

    // whitelist uri
    await memeMachine.addWhitelistedMemeURI(URI, templateId, text);
    // create meme
    await memeMachine.createMeme(templateId, text, imgHash, URI);
    // vote on meme
    await memeMachine.voteOnMeme(1, false);
    const res = await memeMachine.getMeme(1);
    expect(res[2]).to.equal(0);
  });

  it('Mint meme, upvote and upvote again, expect revert with voting cooldown error', async function() {
    // meme info
    const templateId = 0;
    const text = ["some text", "some more text"];
    const imgHash = ethers.utils.hexZeroPad(web3.utils.asciiToHex("12345"), 32);
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";
    // whitelist uri
    await memeMachine.addWhitelistedMemeURI(URI, templateId, text);
    // create meme
    await memeMachine.createMeme(templateId, text, imgHash, URI);
    // vote on meme
    await memeMachine.voteOnMeme(1, true);
    await expect(memeMachine.voteOnMeme(1, true)).to.be.revertedWith("voting cooldown error");
    const res = await memeMachine.getMeme(1);
    expect(res[2]).to.equal(2);
  });

  it('Mint meme, update voting cooldown to 0, upvote and upvote again, expect correct score', async function() {
    // meme info
    const templateId = 0;
    const text = ["some text", "some more text"];
    const imgHash = ethers.utils.hexZeroPad(web3.utils.asciiToHex("12345"), 32);
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";

    await memeMachine.updateVotingCooldownTime(0);
    // whitelist uri
    await memeMachine.addWhitelistedMemeURI(URI, templateId, text);
    // create meme
    await memeMachine.createMeme(templateId, text, imgHash, URI);
    // vote on meme
    await memeMachine.voteOnMeme(1, true);
    await memeMachine.voteOnMeme(1, true);
    const res = await memeMachine.getMeme(1);
    expect(res[2]).to.equal(3);
  });

  it('expect correct royalty info', async function() {
    const res = await memeMachine.royaltyInfo(0, 1000);
    const receiver = res[0];
    const royalty = res[1].toString();
    console.log(royalty);
    expect(receiver).to.equal("0xC6f9519F8e2C2be0bB29A585A894912Ccea62Dc8");
    expect(royalty).to.equal("100");
  });

  it('Update royalties, expect correct royalty info', async function() {
    var id = crypto.randomBytes(32).toString('hex');
    var privateKey = "0x"+id;
    var newAddress = new ethers.Wallet(privateKey).address;
    await memeMachine.updateRoyalties(newAddress, 500);
    const res = await memeMachine.royaltyInfo(1, 1000);
    const receiver = res[0];
    const royalty = res[1].toString();
    expect(receiver).to.equal(newAddress);
    expect(royalty).to.equal("50");
  });

  it('Mint a meme, check originality of same metadata expect not original, check originality of different metadata expect original', async function() {
    const templateId = 0;
    const text = ["some text", "some more text"];
    const imgHash = ethers.utils.hexZeroPad(web3.utils.asciiToHex("12345"), 32);
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";

    // whitelist uri
    await memeMachine.addWhitelistedMemeURI(URI, templateId, text);
    // create meme
    await memeMachine.createMeme(templateId, text, imgHash, URI);
    // check if same meme is original
    const res = await memeMachine.isOriginalMeme(templateId, text);
    expect(res[0]).to.equal(false);
    expect(res[1]).to.equal(1);
    // check if different meme is original
    const res2 = await memeMachine.isOriginalMeme(0, ["some original text"]);
    expect(res2[0]).to.equal(true);
    expect(res2[1]).to.equal(0);
  });

  it('Mint meme, expect original img hash to match, expect different img hash not to match, expect memeId to be returned with imgHash', async function() {
    const templateId = 0;
    const text = ["some text", "some more text"];
    const imgHash = ethers.utils.hexZeroPad(web3.utils.asciiToHex("12345"), 32);
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";
    // whitelist uri
    await memeMachine.addWhitelistedMemeURI(URI, templateId, text);
    // create meme
    await memeMachine.createMeme(templateId, text, imgHash, URI);
    // verify original img hash
    const res = await memeMachine.verifyOriginalImage(1, imgHash);
    // verify different img hash
    const res2 = await memeMachine.verifyOriginalImage(1, ethers.utils.hexZeroPad(web3.utils.asciiToHex("1234"), 32));
    // verify meme with img hash matches id
    const res3 = await memeMachine.getMemeWithImageHash(imgHash);
    expect(res).to.equal(true);
    expect(res2).to.equal(false);
    expect(res3[0]).to.equal(URI);
    expect(res3[1]).to.equal(1);
  });

//   it('Mint none unique  token, expect revert with not unique error', async function() {

//   });
});