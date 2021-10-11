// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC2981ContractWideRoyalties.sol";
import "./IERC721TokenReceiver.sol";

contract DankMinter is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable, ERC2981ContractWideRoyalties {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;
    using SafeMath for uint256;

    uint cooldownTime;
    uint votingCooldownTime;

    address treeFiddyCoinAddress;

    // events
    event NewMeme(bytes32 memeHash, address owner, uint tokenId, string uri);
    event BurnedMeme(uint memeHash, address owner, uint tokenId);
    event UpdatedCooldownTime(uint cooldownTime, string cooldownType);
    event UpdatedVotingPrice(uint price);
    event TransferTreeFiddies(address operator, address from, address to, uint amount);

    // mapping: memeId -> memeHash
    mapping (uint => bytes32) private memeToHash;
    // mapping: hash -> memeId
    mapping (bytes32 => uint) private hashToMeme;
    // mapping: user address -> cooldown time (allows requiring 5 minute cooldown)
    mapping (address => uint) private userCooldown;
    // mapping: user address -> voting cooldown time
    mapping (address => uint) private votingCooldown;
    // mapping: user -> ownedMemes
    mapping (address => uint) private stashedMemes;
    // mapping: memeId -> owner
    mapping (uint => address) private memeStash;
    // mapping: memeId -> posting uris
    mapping (uint => string[]) private memePostings;
    // mapping: address -> tree fiddies
    mapping (address => uint) private treeFiddyBalance;
    // mapping: memeId -> creator address
    mapping (uint => address) private memeCreator;
    // mapping: memeId -> vote score
    mapping (uint => uint) private memeScore; 
    // TODO - add experience tracker
    // TODO - add dankness tier

    // meme struct used for returning memes from function calls
    struct Meme {
        bytes32 memeHash;
        uint score;
        string uri;
        string[] postings;
        uint memeId;
    }

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

    // check if a meme is original (for public use to avoid gas fees trying unoriginal memes)
    function isOriginalMeme(uint32 _templateId, string[] memory _text) public view returns (bool, uint) {
        uint memeId = hashToMeme[_hashContent(_templateId, _text)];
        return (memeId == 0, memeId);
    }

    // creates a new meme
    function createMeme(uint32 _templateId, string[] memory _text, string memory _uri, address _mintToAddress) public {
        // require 10 minute cooldown has passed 
        require(block.timestamp >= userCooldown[_mintToAddress], "cooldown error");
        // get meme hash
        bytes32 memeHash = _hashContent(_templateId, _text);
        // require unique meme hash
        require(hashToMeme[memeHash] == 0, "not unique error");
        // get new token id
        uint newTokenId = _tokenIdCounter.current();
        // set memeid to hash
        memeToHash[newTokenId] = memeHash;
        // map hash to memeid
        hashToMeme[memeHash] = newTokenId;
        // update sender cooldown
        userCooldown[_mintToAddress] = block.timestamp + cooldownTime;
        // map score
        memeScore[newTokenId] = 1;
        // assign owner
        memeStash[newTokenId] = _mintToAddress;
        // assign creator
        memeCreator[newTokenId] = _mintToAddress;
        // mint some treeFiddies, how many? About treefiddy
        treeFiddyBalance[_mintToAddress] = treeFiddyBalance[_mintToAddress].add(3.5 * 10 ** 18);
        // safemint
        safeMint(_mintToAddress, newTokenId);
        // set token uri
        _setTokenURI(newTokenId, _uri);
        // emit event
        emit NewMeme(memeHash, _mintToAddress, newTokenId, _uri);
    }

    // TODO - make this effect meme experience and dankness tier
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

    // TODO - make this effect meme experience and dankness tier
    // function to add a posting link to a meme
    function addPosting(uint _memeId, string memory posting) public {
        require(msg.sender == memeStash[_memeId], "error sender is not the owner");
        memePostings[_memeId].push(posting);
    }

    // TODO - make this effect meme experience and dankness tier
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

    // TODO - make this effect dankness tier
    // tip the creator of a meme
    function tipCreator(uint _memeId, uint amount) public {
        safeTransferTreeFiddiesFrom(msg.sender, memeCreator[_memeId], amount, "");
    }

    // toss a coin to the developer
    function tossACoin(uint amount) public {
        safeTransferTreeFiddiesFrom(msg.sender, owner(), amount, "");
    }

    // sacrifice upon the meme altar
    function sacrificeToMeme(uint _memeId, uint amount) public {
        // TODO - complete
    }

    // getters
    // get creation cooldown
    function getCreationCooldownTime() public view returns (uint) {
        return cooldownTime;
    }

    // get users vote cooldown time (for public use to avoid gas fees trying to vote on memes before cooldown is up)
    function notOnVoteCooldown(address userAddress) public view returns (bool) {
        return (block.timestamp >= votingCooldown[userAddress]);
    }

    // get users creation cooldown time (for public use to avoid gas fees trying to make memes before cooldown is up)
    function notOnMintCooldown(address userAddress) public view returns (bool) {
        return (block.timestamp >= userCooldown[userAddress]);
    }
    
    // gets a tokenId with the template + text hash
    function getMemeWithHash(bytes32 _memeHash) public view returns (string memory, uint) {
        uint memeId = hashToMeme[_memeHash];
        return (tokenURI(memeId), memeId);
    }

    // gets a meme template + text hash with token id
    function getMemeHash(uint _tokenId) internal view returns (bytes32) {
        return memeToHash[_tokenId];
    }

    // gets a meme template + text hash with token id
    function getMemeScore(uint _tokenId) internal view returns (uint) {
        return memeScore[_tokenId];
    }

    // gets meme onchain metadata
    function getMeme(uint _memeId) public view returns (Meme memory) {
        bytes32 memeHash = getMemeHash(_memeId);
        uint score = getMemeScore(_memeId);
        string memory uri = tokenURI(_memeId);
        string[] memory postings = memePostings[_memeId];
        return Meme(memeHash, score, uri, postings, _memeId);
    }

    // gets all memes in passed in array
    function getMemes(uint[] memory _memeIds) public view returns (Meme[] memory) {
        Meme[] memory userMemes = new Meme[](_memeIds.length);
        for (uint i = 0; i < _memeIds.length; i++) {
            userMemes[i] = getMeme(_memeIds[i]);
        }
        return userMemes;
    }

    // gets all the memeIds of memes owned by the sender
    function getUsersMemes(address _userAddress) public view returns (Meme[] memory) {
        uint[] memory result = new uint[](stashedMemes[_userAddress]);
        uint counter = 0;
        for (uint i = 0; i < _tokenIdCounter.current(); i++) {
            if (memeStash[i] == _userAddress) {
                result[counter] = i;
                counter++;
            }
        }
        Meme[] memory userMemes = getMemes(result);
        return userMemes;
    }

    function getNumStashedMemes(address _userAddress) public view returns (uint) {
        return stashedMemes[_userAddress];
    }

    function getTreeFiddyBalance(address _userAddress) public view returns (uint) {
        return treeFiddyBalance[_userAddress];
    }

    function customInitialize() internal {
        cooldownTime = 0 minutes;
        votingCooldownTime = 10 seconds;
        _setRoyalties(0xC6f9519F8e2C2be0bB29A585A894912Ccea62Dc8, 1500);
        _tokenIdCounter.increment();
    }

    function initialize() initializer public {
        __ERC721_init("DankMinter", "MEME");
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
        _safeMint(to, tokenId); // broken line
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


    /* 
    I dislike the ERC1155 multitoken standard because it is geared too much towards games. However I did want
    to include a fungible token in this project, so I decided to implement my own transfer and swap protocol specifically 
    for a single token currency with infinite nonfungible tokens that follow the ERC721 standard. The token inside this contract 
    only implements utilities. For other transactions, it must be swapped for the ERC20 version. 
    TreeFiddyCoin Swap protocol:
    */

    // TODO - handle treefiddy decimals

    /*
    Transfers tree fiddies safely from one account to another.
    */
    function safeTransferTreeFiddiesFrom(
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "TreeFiddy: caller is not owner nor approved"
        );
        _safeTransferTreeFiddiesFrom(from, to, amount, data);
    }

    /*
    Performs safe transfer. 
    */
    function _safeTransferTreeFiddiesFrom(
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC721: transfer to the zero address");

        address operator = _msgSender();
        
        uint256 fromBalance = treeFiddyBalance[from];
        require(fromBalance >= amount, "ERC721: insufficient balance for transfer");
        unchecked {
            treeFiddyBalance[from] = fromBalance - amount;
        }
        treeFiddyBalance[to] += amount;

        emit TransferTreeFiddies(operator, from, to, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, amount, data);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /*
    Approves safe transfer
    */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) private view {
        if (isContract(to)) {
            try IERC721TokenReceiver(to).onERC721TokenReceived(operator, from, amount, data) returns (bytes4 response) {
                if (response != IERC721TokenReceiver.onERC721TokenReceived.selector) {
                    revert("ERC721: ERC721TokenReceiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC721: transfer to non ERC721TokenReceiver implementer");
            }
        }
    }
}