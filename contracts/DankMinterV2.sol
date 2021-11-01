// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "./@rarible/royalties/contracts/LibPart.sol";
import "./@rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "./ERC2981ContractWideRoyalties.sol";
import "./ContentMixin.sol";
import "./TreeFiddy.sol";

contract DankMinterV2 is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable, ERC2981ContractWideRoyalties, ContextMixin, RoyaltiesV2Impl {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;
    using SafeMath for uint256;

    address tipAddress;
    address treeFiddyCoinAddress;
    uint conversionRate;
    TreeFiddy tf;

    // events
    event NewMeme(bytes32 memeHash, address owner, uint tokenId, string uri);
    event BurnedMeme(uint memeHash, address owner, uint tokenId);
    event Tipped(address from, address to, uint amount, uint memeId);
    event Sacrificed(address sacrificer, uint memeId, uint amount);
    event LeveledUpDankness(address source, uint memeId, uint danknessTier);
    event VotedOnMeme(address voter, uint memeId, uint memeScore);
    event AddedPosting(address poster, uint memeId);
    event DeletedPosting(address deleter, uint memeId);
    event UpdatedVotingPrice(uint price);
    event TransferTreeFiddies(address operator, address from, address to, uint amount);
    event SetTreeFiddyCoinAddress(address treeFiddyCoin);

    // mapping: memeId -> memeHash
    mapping (uint => bytes32) private memeToHash;
    // mapping: hash -> memeId
    mapping (bytes32 => uint) private hashToMeme;

    // mapping: memeId -> creator address
    mapping (uint => address) private memeCreator;
    // mapping: meemId -> meme voting score
    mapping (uint => uint) private memeScore;

    // mapping: address -> bool has minted before
    mapping (address => bool) private hasMinted;
    // mapping: address -> memeId -> bool has voted
    mapping (address => mapping (uint => bool)) private hasVotedOnMeme;

    // mapping: memeId -> experience
    mapping (uint => uint) private memeExperience;
    // mapping: memeId -> next level required experience
    mapping (uint => uint) private requiredMemeExperience;
    // mapping: memeId -> dankness tier
    mapping (uint => uint) private memeDanknessTier;

    uint testUpgrade;

    // meme struct used for returning memes from function calls
    struct Meme {
        bytes32 memeHash;
        string uri;
        uint memeId;
        uint score;
        uint danknessTier;
        uint experience;
        uint requiredExperience;
        address creator;
    }

    // struct used to bulk mint memes
    struct MemeToCreate {
        uint32 templateId;
        string[] text;
        string uri;
        address mintToAddress;
    }

    modifier tokenExists(uint _memeId) {
        require(_exists(_memeId), "meme does not exist");
        _;
    }

    // sets the contract address for TreeFiddyCoin
    function setTreeFiddyCoinAddress(address _contractAddr) public onlyOwner {
        treeFiddyCoinAddress = _contractAddr;
        tf = TreeFiddy(treeFiddyCoinAddress);
        emit SetTreeFiddyCoinAddress(treeFiddyCoinAddress);
    }

    // private utility minting function for TreeFiddies
    function _mintTreeFiddies(address _to, uint amount) private {
        tf.mint(_to, amount);
    }

    // private utility burning function for TreeFiddies
    function _burnTreeFiddies(address _from, uint amount) private {
        tf.burnFromDankMinter(_from, amount);
    }

    // private utility transfer function for TreeFiddies
    function _treeFiddyCoinTransferFrom(address _from, address _to, uint amount) private {
        tf.transferDankMinter(_from, _to, amount); 
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

    // check if a hash is original (for public use to avoid gas fees trying unoriginal memes)
    function isOriginalHash(bytes32 _memeHash) public view returns (bool, uint) {
        uint memeId = hashToMeme[_memeHash];
        return (memeId == 0, memeId);
    }

    function batchMintMemes(MemeToCreate[] memory _memesToMint) public onlyOwner {
        for (uint i = 0; i < _memesToMint.length; i++) {
            createMeme(_memesToMint[i].templateId, _memesToMint[i].text, _memesToMint[i].uri, _memesToMint[i].mintToAddress);
        }
    }

    // creates a new meme
    function createMeme(uint32 _templateId, string[] memory _text, string memory _uri, address _mintToAddress) public onlyOwner {
        // get meme hash
        bytes32 memeHash = _hashContent(_templateId, _text);
        // mint or charge treefiddies
        if (hasMinted[_mintToAddress] == false) {
            // mint tree fiddies - how many? about tree fiddy
            _mintTreeFiddies(_mintToAddress, 175 * conversionRate);
            hasMinted[_mintToAddress] = true;
        } else {
            // burn 7 treefiddies
            _burnTreeFiddies(_mintToAddress, 35 * conversionRate);
        }
        // get new token id
        uint newTokenId = _tokenIdCounter.current();
        // set memeid to hash
        memeToHash[newTokenId] = memeHash;
        // map hash to memeid
        hashToMeme[memeHash] = newTokenId;
        // map experience
        memeExperience[newTokenId] = 1;
        // map dankness tier
        memeDanknessTier[newTokenId] = 1;
        // map meme required xp
        requiredMemeExperience[newTokenId] = calculateRequiredMemeXP(1);
        // map voting score
        memeScore[newTokenId] = 1;
        // assign creator
        memeCreator[newTokenId] = _mintToAddress;
        // safemint
        safeMint(_mintToAddress, newTokenId);
        // set token uri
        _setTokenURI(newTokenId, _uri);
        // emit event
        emit NewMeme(memeHash, _mintToAddress, newTokenId, _uri);
    }

    // withdraw vote payments
    function withdraw() external onlyOwner {
        address _owner = owner();
        payable(_owner).transfer(address(this).balance);
    }

    function calculateRequiredMemeXP(uint _memeDanknessTier) private pure returns (uint) {
        uint requiredXP;
        if (_memeDanknessTier < 5) {
            requiredXP = 10 ** (_memeDanknessTier + 1);
        } else {
            requiredXP = 100000 + 20000 * _memeDanknessTier;
        }
        return requiredXP;
    }

    // utility to recalculate dankness tier upon increasing experience
    function recalculateDankness(uint _memeId) private {
        uint experience = memeExperience[_memeId];
        uint requiredExp = requiredMemeExperience[_memeId];
        if (experience >= requiredExp) {
            memeExperience[_memeId] = experience.sub(requiredExp);
            memeDanknessTier[_memeId] = memeDanknessTier[_memeId].add(1);
            requiredMemeExperience[_memeId] = calculateRequiredMemeXP(memeDanknessTier[_memeId]);
            emit LeveledUpDankness(msg.sender, _memeId, memeDanknessTier[_memeId]);
        }
    }
    
    // toss a coin to the developer
    function tossACoin(uint amount) public {
        _treeFiddyCoinTransferFrom(msg.sender, tipAddress, amount);
        emit Tipped(msg.sender, tipAddress, amount, 0);
    }

    // tip the creator of a meme
    function tipCreator(uint _memeId, uint amount) public tokenExists(_memeId) {
        address _to = memeCreator[_memeId];
        _treeFiddyCoinTransferFrom(msg.sender, _to, amount);
        emit Tipped(msg.sender, _to, amount, _memeId);
    }

    // sacrifice upon the meme altar
    function sacrificeToMeme(uint _memeId, uint amount) public tokenExists(_memeId) {
        _burnTreeFiddies(msg.sender, amount);
        uint experienceImpact = (amount * 2) / (3 * conversionRate);
        experienceImpact = experienceImpact.add((amount * 2) / (5 * conversionRate / 10));
        memeExperience[_memeId] = memeExperience[_memeId].add(experienceImpact);
        recalculateDankness(_memeId);
        emit Sacrificed(msg.sender, _memeId, amount);
    }

    // function to vote on a meme (payable to avoid people constantly upvoting their own memes)
    function voteOnMeme(uint _memeId, bool upDown) public tokenExists(_memeId) {
        require(hasVotedOnMeme[msg.sender][_memeId] == false, "already voted on this meme");
        uint reward = 3 * conversionRate;
        reward = reward.add(5 * conversionRate / 10);
        _mintTreeFiddies(msg.sender, reward);
        if (upDown) {
            memeExperience[_memeId] = memeExperience[_memeId].add(25);
            memeScore[_memeId] = memeScore[_memeId].add(1);
        } else {
            if (memeExperience[_memeId] >= 10) {
                memeExperience[_memeId] = memeExperience[_memeId].sub(25);
            }
            memeScore[_memeId] = memeScore[_memeId].sub(1);
        }
        recalculateDankness(_memeId);
        emit VotedOnMeme(msg.sender, _memeId, memeScore[_memeId]);
    }

    // getters
    // gets a tokenId with the template + text hash
    function getMemeWithHash(bytes32 _memeHash) public view returns (Meme memory) {
        uint memeId = hashToMeme[_memeHash];
        return getMeme(memeId);
    }

    // gets a meme template + text hash with token id
    function getMemeHash(uint _tokenId) internal view returns (bytes32) {
        return memeToHash[_tokenId];
    }

    // gets a memes current experience
    function getMemeExperience(uint _tokenId) internal view returns (uint) {
        return memeExperience[_tokenId];
    }

    // gets a memes current dankness tier
    function getMemeDankness(uint _tokenId) internal view returns (uint) {
        return memeDanknessTier[_tokenId];
    }

    // gets current voting score
    function getMemeScore(uint _tokenId) internal view returns (uint) {
        return memeScore[_tokenId];
    }

    // gets meme onchain metadata
    function getMeme(uint _memeId) public view returns (Meme memory) {
        bytes32 memeHash = getMemeHash(_memeId);
        uint experience = getMemeExperience(_memeId);
        uint score = getMemeScore(_memeId);
        uint dankness = getMemeDankness(_memeId);
        string memory uri = tokenURI(_memeId);
        address creator = memeCreator[_memeId];
        uint requiredExperience = requiredMemeExperience[_memeId];
        return Meme(memeHash, uri, _memeId, score, dankness, experience, requiredExperience, creator);
    }

    // gets all memes in passed in array
    function getMemes(uint[] memory _memeIds) public view returns (Meme[] memory) {
        Meme[] memory userMemes = new Meme[](_memeIds.length);
        for (uint i = 0; i < _memeIds.length; i++) {
            userMemes[i] = getMeme(_memeIds[i]);
        }
        return userMemes;
    }

    // gets all memes owned by the address
    function getUsersMemes(address _userAddress) public view returns (Meme[] memory) {
        uint userNumMemes = balanceOf(_userAddress);
        uint[] memory result = new uint[](userNumMemes);
        for (uint i = 0; i < userNumMemes; i++) {
            uint tokenId = tokenOfOwnerByIndex(_userAddress, i);
            result[i] = tokenId;
        }
        return getMemes(result);
    }

    // gets users cumulative dankness
    function getUsersDankness(address _userAddress) public view returns (uint cumulativeDankness) {
        uint userNumMemes = balanceOf(_userAddress);
        cumulativeDankness = 0;
        for (uint i = 0; i < userNumMemes; i++) {
            cumulativeDankness = cumulativeDankness + getMemeDankness(tokenOfOwnerByIndex(_userAddress, i));
        }   
    }

    function getUserInfo(address _userAddress) public view returns (Meme[] memory memes, uint cumulativeDankness) {
        memes = getUsersMemes(_userAddress);
        cumulativeDankness = 0;
        for (uint i = 0; i < memes.length; i++) {
            cumulativeDankness = cumulativeDankness + memes[i].danknessTier;
        }
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

   /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721Upgradeable.isApprovedForAll(_owner, _operator);
    }

    // update EIP-2981 royalty value
    function updateRoyalties(address payable _recipient, uint _royalties) public onlyOwner {
        _setRoyalties(_recipient, _royalties);
        setRoyalties(0, _recipient, uint96(_royalties));
    }

    // set rarible royalties
    function setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) public onlyOwner {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    function customInitialize() internal {
        tipAddress = 0xC6f9519F8e2C2be0bB29A585A894912Ccea62Dc8;
        conversionRate = 10 ** 18;
        _setRoyalties(tipAddress, 1500);
        setRoyalties(0, payable(tipAddress), uint96(1500));
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
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
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

    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        override(ERC2981ContractWideRoyalties, ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}