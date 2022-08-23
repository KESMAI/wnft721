// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Lib.sol";

contract ImageNFT is
  Initializable,
  ERC721Upgradeable,
  ERC721URIStorageUpgradeable,
  UUPSUpgradeable,
  OwnableUpgradeable
{
  using CountersUpgradeable for CountersUpgradeable.Counter;
  CountersUpgradeable.Counter public _tokenIds;

  /// @custom:oz-upgrades-unsafe-allow constructor

  function initialize() public initializer {
    __ERC721_init("ImageNFT", "MTK");
    __ERC721URIStorage_init();
    __Ownable_init();
    __UUPSUpgradeable_init();
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {}

  function _burn(uint256 tokenId)
    internal
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
  {
    super._burn(tokenId);
  }

  function _baseURI()
    internal
    pure
    override(ERC721Upgradeable)
    returns (string memory)
  {
    return "ipfs://";
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI)
    internal
    virtual
    override(ERC721URIStorageUpgradeable)
  {
    _tokenURIs[tokenId] = _tokenURI;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    returns (string memory)
  {
    string memory base = _baseURI();
    string memory _tokenURI = _tokenURIs[tokenId];
    return string(abi.encodePacked(base, _tokenURI));
  }

  //똑같은 이미지 막고
  mapping(uint256 => string) private _tokenURIs;
  mapping(uint256 => Lib.Image) public imageStorage;
  mapping(string => bool) internal tokenCIDExists;

  //민트
  function mintImageNFT(
    string memory tokenName,
    string memory ipfsHashOfPhoto,
    string memory tokenCID,
    uint32 newSale
  ) external {
    _tokenIds.increment();
    require(!_exists(_tokenIds.current()), "ImageID repeated.");
    require(!tokenCIDExists[tokenCID], "Token URI repeated.");
    _safeMint(msg.sender, _tokenIds.current());
    _setTokenURI(_tokenIds.current(), ipfsHashOfPhoto);
    Lib.Image memory newImage = Lib.Image(
      tokenName,
      ipfsHashOfPhoto,
      tokenCID,
      msg.sender,
      msg.sender,
      0,
      newSale,
      _tokenIds.current(),
      false,
      Lib.Status.OffBid
    );
    tokenCIDExists[tokenCID] = true;
    imageStorage[_tokenIds.current()] = newImage;
  }

  //스텟츄만 바꾸고
  function updateStatus(uint256 _tokenID, Lib.Status status) external {
    Lib.Image storage image = imageStorage[_tokenID];
    image.status = status;
  }

  //오너만 바꾸고
  function updateOwner(uint256 _tokenID, address newOwner) external {
    Lib.Image storage image = imageStorage[_tokenID];

    image.currentOwner = newOwner;
    _transfer(ownerOf(_tokenID), newOwner, _tokenID);
  }

  //이미지 가격만 바꾸고
  function updatePrice(uint256 _tokenID, uint256 newPrice) external {
    Lib.Image storage image = imageStorage[_tokenID];
    image.highestBidPrice = newPrice;
  }

  //원화인지 알수잇게
  function updateKRW(uint256 _tokenID, bool _isKRW) external {
    Lib.Image storage image = imageStorage[_tokenID];
    image.isKRW = _isKRW;
  }

  // //소유량 체크
  function getOwnedNumber(address owner) external view returns (uint256) {
    return balanceOf(owner);
  }

  //image반환
  function ImageDate(uint256 tokenId) external view returns (Lib.Image memory) {
    Lib.Image memory imageDate = imageStorage[tokenId];
    return imageDate;
  }

  //이미지 삭제
  function Burn(uint256 tokenId) external {
    _burn(tokenId);

    delete imageStorage[tokenId];
  }
}
