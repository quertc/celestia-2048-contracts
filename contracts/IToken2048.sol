// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IMetadata2048.sol";

interface IToken2048 is IERC20 {
    function mint(address to, uint256 amount) external;
    function metadataController() external view returns(IMetadata2048);
    function createBoardPrice() external view returns(uint256);
}