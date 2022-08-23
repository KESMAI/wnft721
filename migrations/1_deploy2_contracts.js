const { deployProxy } = require("@openzeppelin/truffle-upgrades");
const ImageNFT = artifacts.require("ImageNFT");
const MarketPlace = artifacts.require("MarketPlace");
const Lib = artifacts.require("Lib");
module.exports = async function (deployer) {
  const ImageNFTIns = await deployProxy(ImageNFT, {
    deployer,
  });
  const maininstance = await deployProxy(MarketPlace, [ImageNFTIns.address], {
    deployer,
  });
  const libinstance = await deployProxy(Lib, {
    deployer,
  });

  console.log("Deployed", ImageNFTIns.address);
  console.log("Deployed", maininstance.address);
  console.log("Deployed", libinstance.address);
};
