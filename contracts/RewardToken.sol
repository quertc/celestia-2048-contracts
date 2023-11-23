// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IGame2048 {
    function getBoard(uint256 id) external view returns (address owner, uint256 score);
}

contract RewardToken is ERC1155, Ownable {
    IGame2048 public game2048;
    mapping(uint256 => uint256) public lastClaimedScores;

    error InvalidGame2048Address();
    error NotBoardOwner();
    error NoNewScoreToClaim();

    event RewardClaimed(address indexed boardOwner, uint256 boardId, uint256 scoreToMint);

    constructor(address _game2048Address) ERC1155("") {
        if (_game2048Address == address(0)) revert InvalidGame2048Address();
        game2048 = IGame2048(_game2048Address);
    }

    function claim(uint256 boardId) public {
        (address boardOwner, uint256 currentScore) = game2048.getBoard(boardId);
        if (msg.sender != boardOwner) revert NotBoardOwner();

        uint256 previouslyClaimedScore = lastClaimedScores[boardId];
        if (currentScore <= previouslyClaimedScore) revert NoNewScoreToClaim();

        uint256 scoreToMint = currentScore - previouslyClaimedScore;
        lastClaimedScores[boardId] = currentScore;

        _mint(boardOwner, boardId, scoreToMint, "");
        emit RewardClaimed(boardOwner, boardId, scoreToMint);
    }
}
