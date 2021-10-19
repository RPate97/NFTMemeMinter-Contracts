// test/Box.proxy.js
// Load dependencies
var Web3 = require('web3');
var web3 = new Web3(Web3.givenProvider || "ws://localhost:8545");
var BN = web3.utils.BN;
var crypto = require('crypto');
const { expect } = require('chai');
 
let DankMinter;
let memeMachine;
let TreeFiddy;
let treeFiddy;

// Start test block
describe('MemeMinter (proxy)', function () {
  beforeEach(async function () {
    DankMinter = await ethers.getContractFactory("DankMinter");
    memeMachine = await upgrades.deployProxy(DankMinter, [], {initializer: 'initialize'});

    TreeFiddy = await ethers.getContractFactory("TreeFiddy");
    treeFiddy = await upgrades.deployProxy(TreeFiddy, [memeMachine.address], {initializer: 'initialize'});

    await memeMachine.setTreeFiddyCoinAddress(treeFiddy.address);

    [alice, bob, james] = await ethers.getSigners();
  });

  it('Upgradability works', async () => {
    const MemeMinterV2 = await ethers.getContractFactory("DankMinterV2");
    upgraded = await upgrades.upgradeProxy(memeMachine.address, MemeMinterV2);

    // meme info
    const templateId = 0;
    const text = ["some text", "some more text"];
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";

    // calculate meme hash
    var textStr = "";
    for (var i = 0; i < text.length; i++) {
        textStr += text[i];
    }
    const encoded = web3.eth.abi.encodeParameters(['uint256', 'string'], [templateId, textStr])
    const hash = web3.utils.sha3(encoded, {encoding: 'hex'});

    // create meme
    await upgraded.createMeme(templateId, text, URI, alice.address);
    // get info
    const res = await memeMachine.getMeme(1);
    const memeHash = res[0];
    const memeUri = res[1];
    const memeId = res[2];
    const memeScore = res[3];
    const dankness = res[4];
    const experience = res[5];
    const creatorAddr = res[6];
    const postings = res[7];
    // expect correct info
    expect(memeHash).to.equal(hash, "meme hash is not correct");
    expect(memeId).to.equal(1, "memeId is not correct");
    expect(memeScore).to.equal(1, "score is not correct");
    expect(memeUri).to.equal(memeUri, "uri is not correct");
    expect(dankness).to.equal(1, "dankness tier is not correct");
    expect(experience).to.equal(1, "experience is not correct");
    expect(creatorAddr).to.equal(alice.address, "experience is not correct");
    expect(postings).to.deep.equal([], "postings is not correct");
    // verify memeId returned with hash
    const res2 = await upgraded.getMemeWithHash(hash);
    expect(res2[0]).to.equal(hash, "meme hash is not correct");
    expect(res2[1]).to.equal(memeUri, "uri is not correct");
    expect(res2[2]).to.equal(1, "memeId is not correct");
    expect(res2[3]).to.equal(1, "score is not correct");
    expect(res2[4]).to.equal(1, "dankness tier is not correct");
    expect(res2[5]).to.equal(1, "experience is not correct");
    expect(res2[6]).to.equal(alice.address, "creator address is not correct");
    expect(res2[7]).to.deep.equal([], "postings is not correct");
    // expect correct number of treefiddies
    const res3 = await treeFiddy.balanceOf(alice.address);
    expect(res3.toString()).to.equal("35000000000000000000", 'incorrect number of treefiddies');
  });
 
  it('Mint a token, expect correct URI and correct hash, expect memeId to be returned using hash', async function () {
    // meme info
    const templateId = 0;
    const text = ["some text", "some more text"];
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";

    // calculate meme hash
    var textStr = "";
    for (var i = 0; i < text.length; i++) {
        textStr += text[i];
    }
    const encoded = web3.eth.abi.encodeParameters(['uint256', 'string'], [templateId, textStr])
    const hash = web3.utils.sha3(encoded, {encoding: 'hex'});

    // create meme
    await memeMachine.createMeme(templateId, text, URI, alice.address);
    // get info
    const res = await memeMachine.getMeme(1);
    const memeHash = res[0];
    const memeUri = res[1];
    const memeId = res[2];
    const memeScore = res[3];
    const dankness = res[4];
    const experience = res[5];
    const creatorAddr = res[6];
    const postings = res[7];
    // expect correct info
    expect(memeHash).to.equal(hash, "meme hash is not correct");
    expect(memeId).to.equal(1, "memeId is not correct");
    expect(memeScore).to.equal(1, "score is not correct");
    expect(memeUri).to.equal(memeUri, "uri is not correct");
    expect(dankness).to.equal(1, "dankness tier is not correct");
    expect(experience).to.equal(1, "experience is not correct");
    expect(creatorAddr).to.equal(alice.address, "experience is not correct");
    expect(postings).to.deep.equal([], "postings is not correct");
    // verify memeId returned with hash
    const res2 = await upgraded.getMemeWithHash(hash);
    expect(res2[0]).to.equal(hash, "meme hash is not correct");
    expect(res2[1]).to.equal(memeUri, "uri is not correct");
    expect(res2[2]).to.equal(1, "memeId is not correct");
    expect(res2[3]).to.equal(1, "score is not correct");
    expect(res2[4]).to.equal(1, "dankness tier is not correct");
    expect(res2[5]).to.equal(1, "experience is not correct");
    expect(res2[6]).to.equal(alice.address, "creator address is not correct");
    expect(res2[7]).to.deep.equal([], "postings is not correct");
    // expect correct number of treefiddies
    const res3 = await treeFiddy.balanceOf(alice.address);
    expect(res3.toString()).to.equal("35000000000000000000", 'incorrect number of treefiddies');
  });

  it('Mint token, mint another token and expect revert with cooldown error', async function () {
    // meme info
    const templateId = 0;
    const text = ["some text", "some more text"];
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";
    const URI2 = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv-two";
    // create meme
    await memeMachine.createMeme(templateId, text, URI, alice.address);
    // create another meme and expect revert
    await expect(memeMachine.createMeme(templateId, text, URI2, alice.address)).to.be.revertedWith("cooldown error");
  });

  it('Mint token, update creation cooldown, mint another token and expect revert with not unique', async function () {
    // meme info
    const templateId = 0;
    const text = ["some text", "some more text"];
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";
    const URI2 = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv-two";
    // update cooldown
    await memeMachine.updateCreationCooldownTime(0);
    // create meme
    await memeMachine.createMeme(templateId, text, URI, alice.address);
    // create another meme and expect revert
    await expect(memeMachine.createMeme(templateId, text, URI2, alice.address)).to.be.revertedWith("not unique error");
  });

  it('Mint token, update creation cooldown, mint another token, expect both tokens returned with getUsersMemes', async function () {
    // meme info
    const templateId = 0;
    const text = ["some text", "some more text"];
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";
    const URI2 = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv-two";
    // update cooldown
    await memeMachine.updateCreationCooldownTime(0);
    // create meme
    await memeMachine.createMeme(templateId, text, URI, alice.address);
    // create another meme and expect revert
    await memeMachine.createMeme(1, ["some unique text"], URI2, alice.address);
    // get users memes
    const res = await memeMachine.getUsersMemes(alice.address);
    expect(res[0][2]).to.equal(1);
    expect(res[1][2]).to.equal(2);
    // expect correct number of treefiddies
    const res3 = await treeFiddy.balanceOf(alice.address);
    expect(res3.toString()).to.equal("70000000000000000000", 'incorrect number of treefiddies');
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
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";
    // create meme
    await memeMachine.createMeme(templateId, text, URI, alice.address);
    // vote on meme
    await memeMachine.voteOnMeme(1, true);
    const res = await memeMachine.getMeme(1);
    expect(res[3]).to.equal(2);
    // expect correct number of treefiddies
    const res3 = await treeFiddy.balanceOf(alice.address);
    expect(res3.toString()).to.equal("31500000000000000000", 'incorrect number of treefiddies');
  });

  it('Mint meme and downvote it, expect correct score', async function() {
    // meme info
    const templateId = 0;
    const text = ["some text", "some more text"];
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";
    // create meme
    await memeMachine.createMeme(templateId, text, URI, alice.address);
    // vote on meme
    await memeMachine.voteOnMeme(1, false);
    const res = await memeMachine.getMeme(1);
    expect(res[3]).to.equal(0);
    // expect correct number of treefiddies
    const res3 = await treeFiddy.balanceOf(alice.address);
    expect(res3.toString()).to.equal("31500000000000000000", 'incorrect number of treefiddies');
  });

  it('Mint meme, upvote and upvote again', async function() {
    // meme info
    const templateId = 0;
    const text = ["some text", "some more text"];
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";
    // create meme
    await memeMachine.createMeme(templateId, text, URI, alice.address);
    // vote on meme
    await memeMachine.voteOnMeme(1, true);
    await memeMachine.voteOnMeme(1, true);
    const res = await memeMachine.getMeme(1);
    expect(res[3]).to.equal(3);
    // expect correct number of treefiddies
    const res3 = await treeFiddy.balanceOf(alice.address);
    expect(res3.toString()).to.equal("28000000000000000000", 'incorrect number of treefiddies');
  });

  it('expect correct royalty info', async function() {
    const res = await memeMachine.royaltyInfo(0, 1000);
    const receiver = res[0];
    const royalty = res[1].toString();
    expect(receiver).to.equal("0xC6f9519F8e2C2be0bB29A585A894912Ccea62Dc8");
    expect(royalty).to.equal("150");
  });

  it('expect correct rarible royalty info', async function() {
    const res = await memeMachine.getRaribleV2Royalties(0);
    const receiver = res[0][0];
    const royalty = res[0][1];
    expect(receiver).to.equal("0xC6f9519F8e2C2be0bB29A585A894912Ccea62Dc8");
    expect(royalty).to.equal("1500");
  });

  it('Update royalties, expect correct royalty info and rarible royalty', async function() {
    var id = crypto.randomBytes(32).toString('hex');
    var privateKey = "0x"+id;
    var newAddress = new ethers.Wallet(privateKey).address;
    await memeMachine.updateRoyalties(newAddress, 500);
    const res = await memeMachine.royaltyInfo(1, 1000);
    const receiver = res[0];
    const royalty = res[1].toString();
    expect(receiver).to.equal(newAddress);
    expect(royalty).to.equal("50");
    const res2 = await memeMachine.getRaribleV2Royalties(0);
    const receiver2 = res2[0][0];
    const royalty2 = res2[0][1];
    expect(receiver2).to.equal(newAddress);
    expect(royalty2).to.equal("500");
  });

  it('Mint a meme, check originality of same metadata expect not original, check originality of different metadata expect original', async function() {
    const templateId = 0;
    const text = ["some text", "some more text"];
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";
    // create meme
    await memeMachine.createMeme(templateId, text, URI, alice.address);
    // check if same meme is original
    const res = await memeMachine.isOriginalMeme(templateId, text);
    expect(res[0]).to.equal(false);
    expect(res[1]).to.equal(1);
    // check if different meme is original
    const res2 = await memeMachine.isOriginalMeme(0, ["some original text"]);
    expect(res2[0]).to.equal(true);
    expect(res2[1]).to.equal(0);
  });

  it('Mint meme, add posting to meme, add another posting to meme, remove posting 1 from meme, expect posting 2 uri to resolve correctly', async function() {
    const templateId = 0;
    const text = ["some text", "some more text"];
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";
    const postingOne = "abcd";
    const postingTwo = "abcdefg";
    // create meme
    await memeMachine.createMeme(templateId, text, URI, alice.address);
    // add posting to meme
    await memeMachine.addPosting(1, postingOne);
    await memeMachine.addPosting(1, postingTwo);
    await memeMachine.removePosting(1, 0);
    const res = await memeMachine.getMeme(1);
    expect(res[7][0]).to.equal(postingTwo);
    // expect correct number of treefiddies
    const res3 = await treeFiddy.balanceOf(alice.address);
    expect(res3.toString()).to.equal("21000000000000000000", 'incorrect number of treefiddies');
  });

  it('tip creator, expect correct balances', async function() {
    const templateId = 0;
    const text = ["some text", "some more text"];
    const URI = "ipfs://QmWJBNeQAm9Rh4YaW8GFRnSgwa4dN889VKm9poc2DQPBkv";
    const postingOne = "abcd";
    const postingTwo = "abcdefg";
    // create alice meme
    await memeMachine.createMeme(templateId, text, URI, alice.address);
    // create bob meme
    await memeMachine.createMeme(1, text, URI, bob.address);
    // get meme
    const res = await memeMachine.getMeme(1);
    // bob tip alice
    await memeMachine.connect(bob).tipCreator(res[2], 7);
    // expect correct number of treefiddies
    const res2 = await treeFiddy.balanceOf(alice.address);
    const res3 = await treeFiddy.balanceOf(bob.address);
    expect(res2.toString()).to.equal("35000000000000000007", 'alice has incorrect number of treefiddies');
    expect(res3.toString()).to.equal("34999999999999999993", 'bob has incorrect number of treefiddies');
  })
});