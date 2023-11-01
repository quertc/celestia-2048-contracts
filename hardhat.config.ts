import { config as dotenv } from "dotenv"
dotenv()

import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const PRIVATE_KEY: string = process.env.PRIVATE_KEY!
const ETHERSCAN_API_KEY: string = process.env.ETHERSCAN_API_KEY!

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://bscscan.com/
    apiKey: ETHERSCAN_API_KEY,
  },
  networks: {
    optimism_testnet: {
      url: "https://goerli.optimism.io",
      chainId: 420,
      accounts: [ PRIVATE_KEY ]
    },
    bubs_testnet: {
      url: "https://bubs.calderachain.xyz/http",
      chainId: 1582,
      accounts: [ PRIVATE_KEY ]
    },
    modulargames_testnet: {
      url: "https://modulargames-rpc-testnet.upnodedev.xyz",
      chainId: 42069,
      accounts: [ PRIVATE_KEY ]
    },
  }
};

export default config;
