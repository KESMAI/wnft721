// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Lib.sol";
import "./ImageNFT.sol";

contract MarketPlace is Initializable, UUPSUpgradeable, OwnableUpgradeable {
  /// @custom:oz-upgrades-unsafe-allow constructor
  ImageNFT public ImageNFTaddress;

  event NftTxHistory(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId,
    uint256 price,
    bool isKRW
  );

  function initialize(address Imgnftcontract) public initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
    ImageNFTaddress = ImageNFT(Imgnftcontract);
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {}

  modifier notOnBid(uint256 _tokenID) {
    require(
      ImageNFTaddress.ImageDate(_tokenID).status == Lib.Status.OffBid,
      "Already on auction."
    );
    _;
  }

  //경매검색
  mapping(uint256 => Lib.Auction) public _auctions;
  //판매검색
  mapping(uint256 => Lib.Mart) public _marts;
  //최종가격
  mapping(uint256 => Lib.prices) public listPriceInfo;
  mapping(uint256 => Lib.Bidder[]) internal _bidders;

  //경매등록
  function beginAuction(
    uint256 _tokenID,
    uint256 _minBid,
    uint256 _duration,
    bool _isKRW
  ) external notOnBid(_tokenID) {
    //이미지 권한자 아니면 에러
    require(ImageNFTaddress.ownerOf(_tokenID) == msg.sender, "Only Owner Can");
    ImageNFTaddress.updateStatus(_tokenID, Lib.Status.OnBid);
    ImageNFTaddress.updatePrice(_tokenID, _minBid);
    ImageNFTaddress.updateKRW(_tokenID, _isKRW);
    Lib.Auction memory newAuction = Lib.Auction(
      _tokenID,
      _minBid,
      _minBid,
      _duration,
      payable(msg.sender),
      false,
      false,
      _isKRW
    );
    _auctions[_tokenID] = newAuction;
  }

  //입찰
  function bid(uint256 auctionID, uint256 newBid) external payable {
    Lib.Auction storage auction = _auctions[auctionID];
    //옥션이 종료되면 에러
    require(!auction.ended, "Auction already ended.");
    require(newBid > auction.highestBid, "Lower bid? Joking.");
    ImageNFTaddress.updatePrice(auction.imageID, newBid);
    auction.winner = payable(msg.sender);
    auction.highestBid = newBid;
    Lib.Bidder memory bidder = Lib.Bidder({addr: msg.sender, amount: newBid});
    _bidders[auction.imageID].push(bidder);
  }

  //경매종료
  function endAuction(uint256 auctionID) external payable {
    require(
      ImageNFTaddress.ownerOf(auctionID) == msg.sender,
      "Only Owner Can End a Auction."
    );

    Lib.Auction storage auction = _auctions[auctionID];

    //현재 시간이 옥션 엔드타임보다 크거나 같지 않을때 에러
    require(block.timestamp >= auction.endTime, "Not end time.");
    //옥션 종료가 false면 에러
    require(!auction.ended, "Already Ended.");

    if (auction.winner == msg.sender) {
      ImageNFTaddress.updatePrice(auctionID, listPriceInfo[auctionID].price);
      ImageNFTaddress.updateStatus(auction.imageID, Lib.Status.OffBid);
    } else {
      ImageNFTaddress.updateStatus(auction.imageID, Lib.Status.WaittingClaim);
    }
    auction.ended = true;
  }

  //구매하기
  function claim(uint256 auctionID, uint256 newbid) external payable {
    Lib.Auction storage auction = _auctions[auctionID];
    address existingOwner = ImageNFTaddress.ownerOf(auctionID);
    auction.winner = payable(msg.sender);
    //옥션이 종료되지 않앗거나
    require(auction.ended, "Auction not ended yet.");
    //옥션이 청구중이지 않으면 에러
    require(!auction.claimed, "Auction already claimed.");
    //옥션승리자 가 돈보내는 사람이 아니면 에러
    // require(auction.winner == msg.sender, "Can only be claimed by winner.");
    if (auction.isKRW == true) {
      ImageNFTaddress.updateOwner(auction.imageID, msg.sender);
      ImageNFTaddress.updateStatus(auction.imageID, Lib.Status.OffBid);
      listPriceInfo[auctionID] = Lib.prices(true, newbid);
    } else if (auction.isKRW == false) {
      MintOwnerPay(auction.imageID, newbid);
      ImageNFTaddress.updateOwner(auction.imageID, msg.sender);
      ImageNFTaddress.updateStatus(auction.imageID, Lib.Status.OffBid);
      listPriceInfo[auctionID] = Lib.prices(false, newbid);
    }
    emit NftTxHistory(
      existingOwner,
      msg.sender,
      auctionID,
      newbid,
      auction.isKRW
    );
  }

  //판매등록
  function beginMart(
    uint256 _tokenID,
    uint256 _minBid,
    bool _isKRW
  ) external {
    //주인고 등록자가 맞지 않으면 에러
    require(ImageNFTaddress.ownerOf(_tokenID) == msg.sender, "Only Owner Can");

    ImageNFTaddress.updateStatus(_tokenID, Lib.Status.OnBuy);
    ImageNFTaddress.updatePrice(_tokenID, _minBid);
    ImageNFTaddress.updateKRW(_tokenID, _isKRW);
    Lib.Mart memory newMart = Lib.Mart(_tokenID, _minBid, _isKRW);
    _marts[_tokenID] = newMart;
  }

  //판매종료
  function endBuy(uint256 martID) external {
    //이미지 주인과 종료하는 사람이 맞지않으면 에러
    require(
      ImageNFTaddress.ownerOf(martID) == msg.sender,
      "Only Owner Can End a Auction."
    );

    Lib.Mart storage mart = _marts[martID];
    ImageNFTaddress.updatePrice(martID, listPriceInfo[martID].price);
    ImageNFTaddress.updateStatus(mart.imageID, Lib.Status.OffBid);
  }

  //구매
  function buy(uint256 martID, uint256 newBuy) external payable {
    Lib.Mart storage mart = _marts[martID];
    address existingOwner = ImageNFTaddress.ownerOf(martID);
    //금액이 맞지 않으면 에러
    require(newBuy == mart.buyPrice, " Joking.");
    if (mart.isKRW == true) {
      listPriceInfo[martID] = Lib.prices(true, newBuy);
      ImageNFTaddress.updateOwner(mart.imageID, msg.sender);
      ImageNFTaddress.updateStatus(mart.imageID, Lib.Status.OffBid);
    } else if (mart.isKRW == false) {
      MintOwnerPay(mart.imageID, newBuy);
      ImageNFTaddress.updateOwner(mart.imageID, msg.sender);
      ImageNFTaddress.updateStatus(mart.imageID, Lib.Status.OffBid);
      listPriceInfo[martID] = Lib.prices(false, newBuy);
    }
    emit NftTxHistory(existingOwner, msg.sender, martID, newBuy, mart.isKRW);
  }

  //돈보내기
  function MintOwnerPay(uint256 MintID, uint256 newBid) public payable {
    Lib.Image memory imagedata = ImageNFTaddress.ImageDate(MintID);

    address owner = ImageNFTaddress.ownerOf(MintID);
    //발행자한테 감
    payable(imagedata.mintedBy).transfer(
      (newBid * (imagedata.royalties)) / (100)
    );
    //주인한테 가는돈
    payable(owner).transfer((newBid * ((100) - imagedata.royalties)) / (100));
  }

  function getBidders(uint256 index)
    external
    view
    returns (Lib.Bidder[] memory)
  {
    return (_bidders[index]);
  }
}
