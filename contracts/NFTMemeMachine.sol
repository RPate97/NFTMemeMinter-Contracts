// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC2981ContractWideRoyalties.sol";

contract MemeMinter is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable, ERC2981ContractWideRoyalties {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;
    using SafeMath for uint256;

    uint cooldownTime;
    uint votingCooldownTime;

    // events
    event NewMeme(bytes32 memeHash, address owner, uint tokenId);
    event BurnedMeme(uint memeHash, address owner, uint tokenId);
    event UpdatedCooldownTime(uint cooldownTime, string cooldownType);
    event UpdatedVotingPrice(uint price);

    // mapping: memeId -> memeHash
    mapping (uint => bytes32) private memeToHash;
    // mapping: hash -> memeId
    mapping (bytes32 => uint) private hashToMeme;
    // mapping: memeId -> imgHash (allows checking to see if the original image matches the img in ipfs)
    mapping (uint => bytes32) private memeToImgHash;
    // mapping: imgHash -> memeId (allows requiring original img hashes)
    mapping (bytes32 => uint) private imgHashToMeme;
    // mapping: user address -> cooldown time (allows requiring 5 minute cooldown)
    mapping (address => uint) private userCooldown;

    // removed - whitelist
    // // whitelisted uri mapping: uri -> memeHash
    // mapping (bytes32 => bytes32) private whitelist;
    // // whitelisted uri mapping: uri -> tokenId
    // mapping (bytes32 => uint) private whitelistTokenIds;


    // mapping: user address -> voting cooldown time
    mapping (address => uint) private votingCooldown;
    // mapping: memeId -> vote score
    mapping (uint => uint) private memeScore;
    // mapping: user -> ownedMemes
    mapping (address => uint) private stashedMemes;
    // mapping: memeId -> owner
    mapping (uint => address) private memeStash;
    // mapping: memeId -> posting uris
    mapping (uint => string[]) private memePostings;

    // update cooldown time
    function updateCreationCooldownTime(uint _newCooldownTime) public onlyOwner {
        cooldownTime = _newCooldownTime;
        emit UpdatedCooldownTime(cooldownTime, "creation");
    }

    // updating voting cooldown time
    function updateVotingCooldownTime(uint _newCooldowntime) public onlyOwner {
        votingCooldownTime = _newCooldowntime;
        emit UpdatedCooldownTime(cooldownTime, "voting");
    }

    // hashes the content of a meme
    function _hashContent(uint32 _templateId, string[] memory text) internal pure returns (bytes32) {
        string memory textStr = "";
        for (uint i = 0; i < text.length; i++) {
            textStr = string(abi.encodePacked(textStr, text[i]));
        }
        return keccak256(abi.encode(_templateId, textStr));
    }

    // removed - whitelist
    // // add a whitelisted meme uri
    // function addWhitelistedMemeURI(bytes32 hURI, bytes32 memeHash) public onlyOwner {
    //     whitelist[hURI] = memeHash;
    //     whitelistTokenIds[hURI] = _tokenIdCounter.current();
    //     _tokenIdCounter.increment();
    // }

    // check if a meme is original (for public use to avoid gas fees trying unoriginal memes)
    function isOriginalMeme(uint32 _templateId, string[] memory _text) public view returns (bool, uint) {
        uint memeId = hashToMeme[_hashContent(_templateId, _text)];
        return (memeId == 0, memeId);
    }

    // verifies that the ipfs image is the original
    // compares the memeImgHash with the passed in imgHash and returns result
    function verifyOriginalImage(uint tokenId, bytes32 imgHash) public view returns (bool) {
        return memeToImgHash[tokenId] == imgHash;
    }

    // creates a new meme
    function createMeme(uint32 _templateId, string[] memory _text, bytes32 imgHash, string memory _uri, address mintToAddress) public onlyOwner {
        // require 10 minute cooldown has passed 
        require(block.timestamp >= userCooldown[mintToAddress], "cooldown error");
        // get meme hash
        bytes32 memeHash = _hashContent(_templateId, _text);
        // require unique meme hash
        require(hashToMeme[memeHash] == 0, "not unique error");

        // removed - whitelist
        // get uri hash
        // bytes32 hURI = keccak256(abi.encode(_uri));
        // // require uri whitelisted
        // require(whitelist[hURI] == memeHash, "not whitelisted error");
        // // require img hash is unique
        // require(imgHashToMeme[imgHash] == 0, "not unique img error");
        // // get token id based on uri hash
        // uint newTokenId = whitelistTokenIds[hURI];
        uint newTokenId = _tokenIdCounter.current();

        // set memeid to hash
        memeToHash[newTokenId] = memeHash;
        // map hash to memeid
        hashToMeme[memeHash] = newTokenId;
        // map memeid to image hash
        memeToImgHash[newTokenId] = imgHash;
        // map imgHash to memeId
        imgHashToMeme[imgHash] = newTokenId;
        // update sender cooldown
        userCooldown[mintToAddress] = block.timestamp + cooldownTime;
        // map score
        memeScore[newTokenId] = 1;
        // increment stashed memes
        stashedMemes[mintToAddress] = stashedMemes[mintToAddress].add(1);
        // assign owner
        memeStash[newTokenId] = mintToAddress;
        // safemint
        safeMint(mintToAddress, newTokenId);
        // set token uri
        _setTokenURI(newTokenId, _uri);
        _tokenIdCounter.increment();

        // removed - whitelist
        // remove whitelisted uri
        // whitelist[hURI] = 0;
        // whitelistTokenIds[hURI] = 0;


        // emit event
        emit NewMeme(memeHash, msg.sender, newTokenId);
    }

    // function to vote on a meme (payable to avoid people constantly upvoting their own memes)
    function voteOnMeme(uint _memeId, bool upDown) public {
        require(block.timestamp >= votingCooldown[msg.sender], "voting cooldown error");
        if (upDown) {
            memeScore[_memeId] = memeScore[_memeId].add(1);
        } else {
            memeScore[_memeId] = memeScore[_memeId].sub(1);
        }
        votingCooldown[msg.sender] = block.timestamp + votingCooldownTime;
    }

    // function to add a posting link to a meme
    function addPosting(uint _memeId, string memory posting) public {
        require(msg.sender == memeStash[_memeId], "error sender is not the owner");
        memePostings[_memeId].push(posting);
    }

    // function to remove a posting link to a meme
    function removePosting(uint _memeId, uint index) public {
        require(msg.sender == memeStash[_memeId], "error sender is not the owner");
        string[] storage postings = memePostings[_memeId];
        delete postings[index];
        postings[index] = postings[postings.length - 1];
        delete postings[postings.length - 1];
    }

    // withdraw vote payments
    function withdraw() external onlyOwner {
        address _owner = owner();
        payable(_owner).transfer(address(this).balance);
    }

    // update royalty value
    function updateRoyalties(address _recipient, uint _royalties) public onlyOwner {
        _setRoyalties(_recipient, _royalties);
    }

    // getters
    // get creation cooldown
    function getCreationCooldownTime() public view returns (uint) {
        return cooldownTime;
    }

    // get users vote cooldown time (for public use to avoid gas fees trying to vote on memes before cooldown is up)
    function notOnVoteCooldownTime(address: userAddress) public view returns (uint) {
        return (block.timestamp >= votingCooldown[userAddress]);
    }

    // get users creation cooldown time (for public use to avoid gas fees trying to make memes before cooldown is up)
    function notOnMintCooldownTime(address: userAddress) public view returns (uint) {
        return (block.timestamp >= userCooldown[userAddress]);
    }
    
    // gets a tokenId with the template + text hash
    function getMemeWithHash(bytes32 _memeHash) public view returns (string memory, uint) {
        uint memeId = hashToMeme[_memeHash];
        return (tokenURI(memeId), memeId);
    }

    // gets a meme with the image hash
    function getMemeWithImageHash(bytes32 _imgHash) public view returns (string memory, uint) {
        uint memeId = imgHashToMeme[_imgHash];
        return (tokenURI(memeId), memeId);
    }

    // gets a meme template + text hash with token id
    function getMemeHash(uint _tokenId) internal view returns (bytes32) {
        return memeToHash[_tokenId];
    }

    // gets a meme template + text hash with token id
    function getMemeImgHash(uint _tokenId) internal view returns (bytes32) {
        return memeToImgHash[_tokenId];
    }

    // gets a meme template + text hash with token id
    function getMemeScore(uint _tokenId) internal view returns (uint) {
        return memeScore[_tokenId];
    }

    // gets all meme onchain metadata
    function getMeme(uint _memeId) public view returns (bytes32, bytes32, uint, string memory, string[] memory) {
        bytes32 memeHash = getMemeHash(_memeId);
        bytes32 imgHash = getMemeImgHash(_memeId);
        uint score = getMemeScore(_memeId);
        string memory uri = tokenURI(_memeId);
        string[] memory postings = memePostings[_memeId];
        return (memeHash, imgHash, score, uri, postings);
    }

    // gets all the memeid of memes owned by the sender
    function getUsersMemes() public view returns (uint[] memory) {
        address owner = msg.sender;
        uint[] memory result = new uint[](stashedMemes[owner]);
        uint counter = 0;
        for (uint i = 0; i < _tokenIdCounter.current(); i++) {
            if (memeStash[i] == owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function customInitialize() internal {
        cooldownTime = 5 minutes;
        votingCooldownTime = 10 seconds;
        _setRoyalties(0xC6f9519F8e2C2be0bB29A585A894912Ccea62Dc8, 1000);
        _tokenIdCounter.increment();
    }

    function initialize() initializer public {
        __ERC721_init("NFTMemeMachine", "MEME");
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        customInitialize();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint tokenId) internal {
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
        if (address(from) == address(0x0)) {
            stashedMemes[to] = stashedMemes[to].add(1);
            memeStash[tokenId] = to;
        } else if (address(to) == address(0x0)) {
            stashedMemes[from] = stashedMemes[from].sub(1);
            memeStash[tokenId] = to;
        } else {
            stashedMemes[from] = stashedMemes[from].sub(1);
            stashedMemes[to] = stashedMemes[to].add(1);
            memeStash[tokenId] = to;
        }
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981ContractWideRoyalties, ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}