var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat";
mnemonic = "tell foil harbor summer people put woman country opinion write first switch";
// use to fire up ganache
// ganache-cli --mnemonic "tell foil harbor summer people put woman country opinion write first switch" -a 40
module.exports = {
  networks: {
    development: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:8545/", 0, 50);
      },
      network_id: '*',
      //gas: 9999999
    }
  },
  compilers: {
    solc: {
      version: "^0.4.24"
    }
  }
};