// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Lib {
  enum Status {
    OffBid,
    OnBid,
    OnBuy,
    WaittingClaim
  }
  struct Mart {
    uint256 imageID;
    uint256 buyPrice;
    bool isKRW;
  }
  struct Image {
    string tokenName;
    string tokenURI;
    string tokenCID;
    address mintedBy;
    address currentOwner;
    uint256 highestBidPrice;
    uint256 royalties;
    uint256 tokenID;
    bool isKRW;
    Status status;
  }

  struct Auction {
    uint256 imageID;
    uint256 startBid;
    uint256 highestBid;
    uint256 endTime;
    address payable winner;
    bool ended;
    bool claimed;
    bool isKRW;
  }
  struct prices {
    bool isKRW;
    uint256 price;
  }
  struct Bidder {
    address addr;
    uint256 amount;
  }
}
