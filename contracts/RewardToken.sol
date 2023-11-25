// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct Board {
    address owner;
    address controller;
    uint256 id;
    uint256 score;
    uint256 maxTile;
    uint256 moves;
    // bool active;
    uint256[] tiles;
}

interface IGame2048 {
    function getBoard(uint256 id) external view returns (Board memory);
}

contract RewardToken is ERC1155, Ownable {
    IGame2048 public game2048;
    mapping(uint256 => uint256) public lastClaimedScores;

    error InvalidGame2048Address();
    error NotBoardOwner();
    error NoNewScoreToClaim();

    event RewardClaimed(address indexed boardOwner, uint256 boardId, uint256 scoreToMint);

    constructor(address _game2048Address) ERC1155("") {
        setGame2048Address(_game2048Address);
    }

    function setGame2048Address(address _game2048Address) public onlyOwner {
        if (_game2048Address == address(0)) revert InvalidGame2048Address();
        game2048 = IGame2048(_game2048Address);
    }

    function claim(uint256 boardId) public {
        Board memory board = game2048.getBoard(boardId);
        if (msg.sender != board.owner) revert NotBoardOwner();

        uint256 previouslyClaimedScore = lastClaimedScores[boardId];
        if (board.score <= previouslyClaimedScore) revert NoNewScoreToClaim();

        uint256 scoreToMint = board.score - previouslyClaimedScore;
        lastClaimedScores[boardId] = board.score;

        _mint(board.owner, boardId, scoreToMint, "");
        emit RewardClaimed(board.owner, boardId, scoreToMint);
    }

    function getLastClaimedScore(uint256 boardId) external view returns (uint256) {
        return lastClaimedScores[boardId];
    }
}
