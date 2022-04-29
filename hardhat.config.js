/**
 * @type import('hardhat/config').HardhatUserConfig
 */
//require("dotenv").config();
require('@nomiclabs/hardhat-waffle');
require("@nomiclabs/hardhat-etherscan");
require('@nomiclabs/hardhat-ethers');
require('@openzeppelin/hardhat-upgrades');
module.exports = {
    solidity: {
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
        compilers: [
            {
                version: "0.8.3",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            }
        ]
    },

    networks : {
      hardhat : { chainId : 1337 }

} }
