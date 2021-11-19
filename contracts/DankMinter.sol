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
import "@openzeppelin/contracts/utils/Strings.sol";
import "./@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "./@rarible/royalties/contracts/LibPart.sol";
import "./@rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "./ERC2981ContractWideRoyalties.sol";
import "./ContentMixin.sol";
import "./IMintable.sol";
import "./utils/Minting.sol";

contract DankMeme is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, PausableUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable, ERC2981ContractWideRoyalties, ContextMixin, RoyaltiesV2Impl, IMintable {

    // events
    event MemeMinted(bytes32 memeHash, address owner, uint tokenId, string uri);
    event MemeBurned(bytes32 memeHash, address owner, uint tokenId);

    address public imx;
    string private baseURI;

    // mapping: memeId -> memeHash
    mapping (uint => bytes32) private memeToHash;
    // mapping: hash -> memeId
    mapping (bytes32 => uint) private hashToMeme;
    // mapping: memeId -> creator address
    mapping (uint => address) private memeCreator;

    // meme struct used for returning memes from function calls
    struct Meme {
        bytes32 memeHash;
        string uri;
        uint memeId;
        address creator;
    }

    modifier onlyIMX() {
        require(msg.sender == imx, "Function can only be called by IMX");
        _;
    }

    // check if a meme is original
    function isOriginalMeme(bytes32 _memeHash) public view returns (bool, uint) {
        uint memeId = hashToMeme[_memeHash];
        return (memeId == 0, memeId);
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

    // gets meme onchain metadata
    function getMeme(uint _memeId) public view returns (Meme memory) {
        bytes32 memeHash = getMemeHash(_memeId);
        string memory uri = tokenURI(_memeId);
        address creator = memeCreator[_memeId];
        return Meme(memeHash, uri, _memeId, creator);
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

    function mintFor(
        address user,
        uint256 quantity,
        bytes calldata mintingBlob
    ) external override onlyIMX {
        require(quantity == 1, "Mintable: invalid quantity");
        (uint256 id, bytes32 _hash, address _creator) = Minting.split(mintingBlob);
        _mintFor(user, id, _hash, _creator);
    }

    function _mintFor(
        address user,
        uint256 id,
        bytes32 _hash,
        address _creator
    ) internal {
        // set memeid to hash
        memeToHash[id] = _hash;
        // map hash to memeid
        hashToMeme[_hash] = id;
        // assign creator
        memeCreator[id] = _creator;
        _safeMint(user, id);
        emit MemeMinted(_hash, _creator, id, tokenURI(id));
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

    function customInitialize(address _owner, address _imx, string calldata _uri) internal {
        require(_owner != address(0), "Owner must not be empty");
        imx = _imx;
        baseURI = _uri;
        transferOwnership(_owner); 
        _setRoyalties(_owner, 1000);
        setRoyalties(0, payable(_owner), uint96(1000));
    }

    function initialize(address _owner, address _imx, string calldata _uri) initializer public {
        customInitialize(_owner, _imx, _uri);
        __ERC721_init("DankMeme", "MEME");
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
    }

    function setBaseTokenURI(string calldata _uri) public onlyOwner {
        baseURI = _uri;
    }

    function baseTokenURI() public view returns (string memory) {
        return baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable)
    {
        emit MemeBurned(memeToHash[tokenId], ownerOf(tokenId), tokenId);
        super._burn(tokenId);
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), '/contract'));
    }

    function tokenURI(uint256 _tokenId) override(ERC721Upgradeable) public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
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