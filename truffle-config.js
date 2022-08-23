require("dotenv").config();

const fs = require("fs");
const path = require("path");
// const HDWalletProvider = require("truffle-hdwallet-provider-privkey");
const HDWalletProvider = require("truffle-hdwallet-provider-klaytn");
// const privateKeys = process.env.PRIVATE_KEYS || "";
// const INFURA_API_KEY="https://mainnet.infura.io/v3/a6133da368b044e4ac867f17244de67b"
// const PRIVATE_KEYS ="1d41042bc397622377f28c3babae80f99df42ec8023e51dfcf079c38b0d25721"
const { INFURA_API_KEY, PRIVATE_KEYS } = process.env;
//scret만 바꿔주면댐
const mnemonic = fs.readFileSync("migrations/.secret").toString().trim();
const GASLIMIT = "20000000";
module.exports = {
  contracts_build_directory: path.join(__dirname, "./build/contracts"),
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*", //match any network id
    },

    klaytn: {
      // provider: function () {
      //   return new HDWalletProvider(
      //     // privateKeys.split(","), // array of private keys
      //     mnemonic , `https://rinkeby.infura.io/v3/${INFURA_API_KEY}` // Url to an Ethereum node
      //   );
      // },
      provider: () =>
        new HDWalletProvider(
          "0xa58c8913d0f53aa2bdd8740b8e105857d4f4429e863f91aef00423bd8eb71439",
          `https://api.baobab.klaytn.net:8651`,
        ),
      gas: "8500000",
      gasPrice: null,
      network_id: 1001,
    },
  },
  contracts_directory: "./contracts",
  contracts_build_directory: "./build/contracts",
  plugins: ["truffle-plugin-verify"],
  api_keys: {},
  // Configure your compilers
  compilers: {
    solc: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      version: "^0.8.0",
    },
  },
};
