require("@nomiclabs/hardhat-waffle");
const fs = require('fs');

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

let alchemyUrl = JSON.parse(fs.readFileSync('./alchemy.config.json','utf-8')).url;

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.7.3",
  networks: {
    hardhat: {
      chainId: 1337,
      forking: {
        url: alchemyUrl
      }
    },
    mainnet: {
      url: alchemyUrl
    }
  }
};

