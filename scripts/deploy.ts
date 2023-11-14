import { ethers } from "hardhat";

async function main() {
  const token = await ethers.deployContract("Token2048", [], {
    nonce: 0,
  });
  await token.waitForDeployment();

  console.log("Token2048", await token.getAddress())

  const game = await ethers.deployContract("Game2048", [ await token.getAddress() ], {
    nonce: 1,
  });
  await game.waitForDeployment();

  console.log("Game2048", await game.getAddress())

  await (await token.setMinter(await game.getAddress(), true)).wait()

  console.log("Allowed Game2048 as a minter")
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
