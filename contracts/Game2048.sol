// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IToken2048.sol";

contract Game2048 is ERC721("2048 Board", "2048B") {
    IToken2048 public immutable token2048;

    constructor(IToken2048 _token2048) {
        token2048 = _token2048;
    }

    enum MoveDirection {
        UP,
        DOWN,
        LEFT,
        RIGHT
    }

    struct Board {
        address owner;
        uint256 id;
        uint256 score;
        bool active;
        uint256[] tiles;
    }
    Board[] private boards;

    function getBoard(uint256 id) public view returns (Board memory) {
        return boards[id];
    }

    modifier onlyBoardOwner(uint256 boardId) {
        require(msg.sender == boards[boardId].owner, "Not board owner");
        require(boards[boardId].active, "Board finished");
        _;
    }

    // Note: pseudo random but good enough on OP Stack as block.difficulty is a random value
    function random(uint256 nonce) public view returns (uint256) {
        return
            uint(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, nonce)
                )
            );
    }

    function _resetBoard(uint256[] memory tiles) internal pure {
        tiles[0] = 0;
        tiles[1] = 0;
        tiles[2] = 0;
        tiles[3] = 0;
        tiles[4] = 0;
        tiles[5] = 0;
        tiles[6] = 0;
        tiles[7] = 0;
        tiles[8] = 0;
        tiles[9] = 0;
        tiles[10] = 0;
        tiles[11] = 0;
        tiles[12] = 0;
        tiles[13] = 0;
        tiles[14] = 0;
        tiles[15] = 0;
    }

    function _new2(
        Board memory board
    ) internal view returns (uint256 newIndex, uint256 totalMissing) {
        unchecked {
            uint256[16] memory missing;

            for (uint256 i; i < 16; ++i) {
                if (board.tiles[i] == 0) {
                    missing[totalMissing++] = i;
                }
            }

            require(totalMissing > 0, "Board full");

            newIndex = missing[
                random(board.score * block.timestamp) % totalMissing
            ];

            board.tiles[newIndex] = 2;
        }
    }

    // Anybody can create their own board
    event CreateBoard(
        address indexed owner,
        uint256 indexed nonce,
        uint256 indexed boardId,
        uint256 startIndex
    );

    function createBoard(
        uint256 nonce
    ) public returns (uint256 boardId, uint256 startIndex) {
        uint256[] memory tiles = new uint256[](16);

        _resetBoard(tiles);

        startIndex = random(nonce) % 16;

        tiles[startIndex] = 2;

        boardId = boards.length;

        boards.push(
            Board({
                owner: msg.sender,
                id: boardId,
                score: 0,
                active: true,
                tiles: tiles
            })
        );

        _mint(msg.sender, boardId);

        emit CreateBoard(msg.sender, nonce, boardId, startIndex);
    }

    function _moveUp(Board memory board) internal pure returns (uint256 score) {
        unchecked {
            uint256[] memory tiles = board.tiles;
            uint256[4][4] memory pipes;
            uint8[4] memory pipeIndex = [0, 0, 0, 0];

            bytes32 tilesHash = keccak256(abi.encodePacked(tiles));

            for (uint256 col; col < 4; ++col) {
                for (uint256 row = 0; row < 4; ++row) {
                    uint256 index = (3 - row) * 4 + col;
                    if (tiles[index] > 0) {
                        pipes[col][pipeIndex[col]++] = tiles[index];
                    }
                }
            }

            _resetBoard(tiles);

            uint256 stackPop = 0;
            uint8[4] memory tileIndex = [0, 0, 0, 0];

            for (uint256 col; col < 4; ++col) {
                uint256 pipeLength = pipeIndex[col];
                for (uint256 i; i < pipeLength; ++i) {
                    uint256 pipeVal = pipes[col][pipeLength - i - 1];
                    if (stackPop != pipeVal) {
                        stackPop = pipeVal;
                        tiles[(tileIndex[col]++) * 4 + col] = stackPop;
                    } else {
                        tiles[(tileIndex[col] - 1) * 4 + col] = stackPop * 2;
                        score += stackPop * 2;
                        stackPop = 0;
                    }
                }

                stackPop = 0;
            }

            require(keccak256(abi.encodePacked(tiles)) != tilesHash, "No movement");
        }
    }

    function _moveDown(
        Board memory board
    ) internal pure returns (uint256 score) {
        unchecked {
            uint256[] memory tiles = board.tiles;
            uint256[4][4] memory pipes;
            uint8[4] memory pipeIndex = [0, 0, 0, 0];

            bytes32 tilesHash = keccak256(abi.encodePacked(tiles));

            for (uint256 col; col < 4; ++col) {
                for (uint256 row = 0; row < 4; ++row) {
                    uint256 index = row * 4 + col;
                    if (tiles[index] > 0) {
                        pipes[col][pipeIndex[col]++] = tiles[index];
                    }
                }
            }

            _resetBoard(tiles);

            uint256 stackPop = 0;
            uint8[4] memory tileIndex = [3, 3, 3, 3];

            for (uint256 col; col < 4; ++col) {
                uint256 pipeLength = pipeIndex[col];
                for (uint256 i; i < pipeLength; ++i) {
                    uint256 pipeVal = pipes[col][pipeLength - i - 1];
                    if (stackPop != pipeVal) {
                        stackPop = pipeVal;
                        tiles[(tileIndex[col]--) * 4 + col] = stackPop;
                    } else {
                        tiles[(tileIndex[col] + 1) * 4 + col] = stackPop * 2;
                        score += stackPop * 2;
                        stackPop = 0;
                    }
                }

                stackPop = 0;
            }

            require(keccak256(abi.encodePacked(tiles)) != tilesHash, "No movement");
        }
    }

    function _moveLeft(
        Board memory board
    ) internal pure returns (uint256 score) {
        unchecked {
            uint256[] memory tiles = board.tiles;
            uint256[4][4] memory pipes;
            uint8[4] memory pipeIndex = [0, 0, 0, 0];

            bytes32 tilesHash = keccak256(abi.encodePacked(tiles));

            for (uint256 row; row < 4; ++row) {
                for (uint256 col = 0; col < 4; ++col) {
                    uint256 index = row * 4 + 3 - col;
                    if (tiles[index] > 0) {
                        pipes[row][pipeIndex[row]++] = tiles[index];
                    }
                }
            }

            _resetBoard(tiles);

            uint256 stackPop = 0;
            uint8[4] memory tileIndex = [0, 0, 0, 0];

            for (uint256 row; row < 4; ++row) {
                uint256 pipeLength = pipeIndex[row];
                for (uint256 i; i < pipeLength; ++i) {
                    uint256 pipeVal = pipes[row][pipeLength - i - 1];
                    if (stackPop != pipeVal) {
                        stackPop = pipeVal;
                        tiles[row * 4 + (tileIndex[row]++)] = stackPop;
                    } else {
                        tiles[row * 4 + (tileIndex[row] - 1)] = stackPop * 2;
                        score += stackPop * 2;
                        stackPop = 0;
                    }
                }

                stackPop = 0;
            }

            require(keccak256(abi.encodePacked(tiles)) != tilesHash, "No movement");
        }
    }

    function _moveRight(
        Board memory board
    ) internal pure returns (uint256 score) {
        unchecked {
            uint256[] memory tiles = board.tiles;
            uint256[4][4] memory pipes;
            uint8[4] memory pipeIndex = [0, 0, 0, 0];

            bytes32 tilesHash = keccak256(abi.encodePacked(tiles));

            for (uint256 row; row < 4; ++row) {
                for (uint256 col = 0; col < 4; ++col) {
                    uint256 index = row * 4 + col;
                    if (tiles[index] > 0) {
                        pipes[row][pipeIndex[row]++] = tiles[index];
                    }
                }
            }

            _resetBoard(tiles);

            uint256 stackPop = 0;
            uint8[4] memory tileIndex = [0, 0, 0, 0];

            for (uint256 row; row < 4; ++row) {
                uint256 pipeLength = pipeIndex[row];
                for (uint256 i; i < pipeLength; ++i) {
                    uint256 pipeVal = pipes[row][pipeLength - i - 1];
                    if (stackPop != pipeVal) {
                        stackPop = pipeVal;
                        tiles[row * 4 + 3 - (tileIndex[row]++)] = stackPop;
                    } else {
                        tiles[row * 4 + 3 - (tileIndex[row] - 1)] =
                            stackPop *
                            2;
                        score += stackPop * 2;
                        stackPop = 0;
                    }
                }

                stackPop = 0;
            }

            require(keccak256(abi.encodePacked(tiles)) != tilesHash, "No movement");
        }
    }

    event Move(
        address indexed owner,
        uint256 indexed boardId,
        MoveDirection indexed dir,
        uint256 newIndex,
        uint256 extraScore,
        uint256 totalScore
    );

    function move(
        uint256 boardId,
        MoveDirection dir
    ) public onlyBoardOwner(boardId) {
        Board memory board = boards[boardId];
        uint256 extraScore;

        if (dir == MoveDirection.UP) {
            extraScore = _moveUp(board);
        } else if (dir == MoveDirection.DOWN) {
            extraScore = _moveDown(board);
        } else if (dir == MoveDirection.LEFT) {
            extraScore = _moveLeft(board);
        } else if (dir == MoveDirection.RIGHT) {
            extraScore = _moveRight(board);
        }

        board.score += extraScore;

        (uint256 newIndex, uint256 totalMissing) = _new2(board);

        boards[boardId] = board;

        if (totalMissing <= 1) {
            endGame(boardId);
        }

        emit Move(msg.sender, boardId, dir, newIndex, extraScore, board.score);
    }

    event EndGame(
        address indexed owner,
        uint256 indexed boardId,
        uint256 totalScore
    );
    function endGame(uint256 boardId) public onlyBoardOwner(boardId) {
        uint256 score = boards[boardId].score;

        boards[boardId].active = false;

        if (address(token2048) != address(0)) {
            token2048.mint(msg.sender, score);
        }

        emit EndGame(msg.sender, boardId, score);
    }

    function tokenURI(uint256 tokenId) public virtual override view returns(string memory) {
        IMetadata2048 metadata = token2048.metadataController();
        if (address(metadata) == address(0)) {
            return "";
        }
        
        return metadata.tokenURI(tokenId);
    }
}
