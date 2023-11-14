import { ethers } from 'hardhat'
import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { Game2048, Token2048 } from '../typechain-types'
import { parseEther } from 'ethers'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, deployments, network } = hre
  const { deploy, run } = deployments
  const { deployer } = await getNamedAccounts()

  const token2048 = await ethers.getContract('Token2048') as Token2048

  await deploy('Game2048', {
    from: deployer,
    proxy: {
      execute: {
        init: {
          methodName: 'initialize',
          args: [deployer, await token2048.getAddress()],
        }
      },
      proxyContract: "OpenZeppelinTransparentProxy",
    },
    deterministicDeployment: "0x2048",
    gasPrice: "10000000",
  })

  const game2048 = await ethers.getContract('Game2048') as Game2048

  // Set game2048 as minter
  await (await token2048.setMinter(await game2048.getAddress(), true)).wait()

  // Set initial price = 0.00005 ETH
  await (await game2048.setCreateBoardPrice(
    "0x0000000000000000000000000000000000000000",
    parseEther("0.00005"),
  )).wait()
}

func.id = 'game2048'
func.tags = []
func.dependencies = []

export default func