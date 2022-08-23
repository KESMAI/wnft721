// migrations/MM_upgrade_box_contract.js
const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const ImageNFT = artifacts.require("ImageNFT");
const ImageNFTV2 = artifacts.require("ImageNFTV2");
const Marketplace = artifacts.require("MarketPlace");
const MarketplaceV2 = artifacts.require("MarketPlaceV2");
module.exports = async function (deployer) {
  const existing = await ImageNFT.deployed();
  const instance = await upgradeProxy(existing.address, ImageNFTV2, {
    deployer,
  });
  const V2existing = await Marketplace.deployed();
  const marketinstance = await upgradeProxy(V2existing.address, MarketplaceV2, {
    deployer,
  });

  console.log("Upgraded", instance.address);
  console.log("MarketUpgraded", marketinstance.address);
};
