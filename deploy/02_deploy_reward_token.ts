import { DeployFunction } from 'hardhat-deploy/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

const deployRewardToken: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const game2048Address = '0xb6bc3b49b3f6C4237851A6E1e918b40d843D8491';

  await deploy('RewardToken', {
    from: deployer,
    args: [game2048Address],
    log: true,
    // deterministicDeployment: '0x2048',
  });
};

deployRewardToken.id = 'deploy_reward_token';
deployRewardToken.tags = ['RewardToken'];
deployRewardToken.dependencies = ['game2048'];

export default deployRewardToken;
