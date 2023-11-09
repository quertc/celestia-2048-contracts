import { ethers } from 'hardhat'
import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, deployments, network } = hre
  const { deploy, run } = deployments
  const { deployer } = await getNamedAccounts()

  await deploy('Token2048', {
    from: deployer,
    args: [deployer],
    deterministicDeployment: "0x2048",
  })
}

func.id = 'token2048'
func.tags = []
func.dependencies = []

export default func