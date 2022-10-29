// test/Box.proxy.js
// Load dependencies
var Web3 = require('web3');
var web3 = new Web3(Web3.givenProvider || "ws://localhost:8545");
var BN = web3.utils.BN;
var crypto = require('crypto');
const { expect } = require('chai');

let memeMachine;

function toHex(str) {
  let result = '';
  for (let i=0; i < str.length; i++) {
    result += str.charCodeAt(i).toString(16);
  }
  return '0x' + result;
}

function fromHex(str1) {
	let hex = str1.toString().substr(2);
	let str = '';
	for (let n = 0; n < hex.length; n += 2) {
		str += String.fromCharCode(parseInt(hex.substr(n, 2), 16));
	}
	return str;
}

// Start test block
describe('DankMeme (proxy)', function () {
  beforeEach(async function () {
    let DankMeme = await ethers.getContractFactory("DankMinter");
    [deployer, alice, bob, james] = await ethers.getSigners();
    // address _owner, address _imx, string calldata _uri
    memeMachine = await upgrades.deployProxy(DankMeme, [deployer.address, deployer.address, 'https://dankminter.com/api/'], {initializer: 'initialize'});
  });

  it('Upgradability works', async () => {
    const DankMemeV2 = await ethers.getContractFactory("DankMinterV2");
    upgraded = await upgrades.upgradeProxy(memeMachine.address, DankMemeV2);

    // meme info
    const templateId = 1;
    const text = ["some text", "some more text"];
    const URI = "https://dankminter.com/api/1";

    // calculate meme hash
    var textStr = "";
    for (var i = 0; i < text.length; i++) {
        textStr += text[i];
    }
    // const encoded = web3.eth.abi.encodeParameters(['uint256', 'string'], [templateId, textStr])
    const hash = web3.utils.sha3("1R1L61fb369f36825cd041da078361fb36a236825cd041da0784EVERYONEMAKINGMEMESABOUTNFTSMEMAKINGNFTSOFMYMEMES", {encoding: 'hex'});

    console.log(hash);
    const blob = toHex(`{1}:{${hash}:@pate}`);
    console.log(blob);

    await upgraded.mintFor("0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0", 1, blob);

    // get info
    const res = await upgraded.getMeme(1);
    console.log(res);
    const memeHash = res[0];
    const memeUri = res[1];
    const memeId = res[2];
    const creator = res[3];
    // expect correct info
    expect(memeHash).to.equal(hash, "meme hash is not correct");
    expect(memeId).to.equal(1, "memeId is not correct");
    expect(memeUri).to.equal(URI, "uri is not correct");
    expect(creator).to.equal("@pate", "creator name is not correct");
    // verify memeId returned with hash
    const res2 = await upgraded.getMemeWithHash(hash);
    expect(res2[0]).to.equal(hash, "meme hash is not correct");
    expect(res2[1]).to.equal(URI, "uri is not correct");
    expect(res2[2]).to.equal(1, "memeId is not correct");
    expect(res2[3]).to.equal("@pate", "creator name is not correct");
  });
 
  it('Mint a token, expect correct URI and correct hash, expect memeId to be returned using hash', async function () {
    // meme info
    const templateId = 1;
    const text = ["some text", "some more text"];
    const URI = "https://dankminter.com/api/1";

    // calculate meme hash
    var textStr = "";
    for (var i = 0; i < text.length; i++) {
        textStr += text[i];
    }
    const encoded = web3.eth.abi.encodeParameters(['uint256', 'string'], [templateId, textStr])
    const hash = web3.utils.sha3(encoded, {encoding: 'hex'});

    const blob = toHex(`{1}:{${hash}:alice}`);

    await memeMachine.mintFor(alice.address, 1, blob);

    // get info
    const res = await memeMachine.getMeme(1);
    const memeHash = res[0];
    const memeUri = res[1];
    const memeId = res[2];
    const creator = res[3];
    // expect correct info
    expect(memeHash).to.equal(hash, "meme hash is not correct");
    expect(memeId).to.equal(1, "memeId is not correct");
    expect(memeUri).to.equal(URI, "uri is not correct");
    expect(creator).to.equal("alice", "creator name is not correct");
    // verify memeId returned with hash
    const res2 = await memeMachine.getMemeWithHash(hash);
    expect(res2[0]).to.equal(hash, "meme hash is not correct");
    expect(res2[1]).to.equal(URI, "uri is not correct");
    expect(res2[2]).to.equal(1, "memeId is not correct");
    expect(res2[3]).to.equal("alice", "creator name is not correct");
  });

  it('Mint token, mint another token, expect both tokens returned with getUsersMemes', async function () {
    // meme info
    const templateId = 1;
    const text = ["some text", "some more text"];
    const URI = "https://dankminter.com/api/1";

    // calculate meme hash
    var textStr = "";
    for (var i = 0; i < text.length; i++) {
        textStr += text[i];
    }
    const encoded = web3.eth.abi.encodeParameters(['uint256', 'string'], [templateId, textStr])
    const hash = web3.utils.sha3(encoded, {encoding: 'hex'});

    // calculate meme hash
    const encoded2 = web3.eth.abi.encodeParameters(['uint256', 'string'], [2, 'other text'])
    const hash2 = web3.utils.sha3(encoded2, {encoding: 'hex'});

    const blob = toHex(`{1}:{${hash}:alice}`);
    const blob2 = toHex(`{2}:{${hash2}:bob}`);

    // create meme
    await memeMachine.mintFor(alice.address, 1, blob);
    // create another meme and expect revert
    await memeMachine.mintFor(alice.address, 1, blob2);

    // get users memes
    const res = await memeMachine.getUsersMemes(alice.address);
    expect(res[0][2]).to.equal(1);
    expect(res[1][2]).to.equal(2);
  });

  it('expect correct royalty info', async function() {
    const res = await memeMachine.royaltyInfo(0, 1000);
    const receiver = res[0];
    const royalty = res[1].toString();
    expect(receiver).to.equal(deployer.address);
    expect(royalty).to.equal("100");
  });

  it('expect correct rarible royalty info', async function() {
    const res = await memeMachine.getRaribleV2Royalties(0);
    const receiver = res[0][0];
    const royalty = res[0][1];
    expect(receiver).to.equal(deployer.address);
    expect(royalty).to.equal("1000");
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


});