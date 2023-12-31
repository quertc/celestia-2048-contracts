// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IToken2048.sol";
import "./Initializable.sol";

contract Game2048 is ERC721("2048 Board", "2048B"), Initializable {
    IToken2048 public token2048;
    IMetadata2048 public metadataController;
    address public admin;
    mapping(address => uint256) public createBoardPrice;

    enum MoveDirection {
        UP,
        DOWN,
        LEFT,
        RIGHT
    }

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
    Board[] private boards;
    mapping(address => uint256) public highScores;

    uint256[100] private __gap;

    modifier onlyBoardController(uint256 boardId) {
        require(msg.sender == boards[boardId].owner || msg.sender == boards[boardId].controller, "Not board owner");
        // require(boards[boardId].active, "Board finished");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == admin, "Forbidden");
        _;
    }

    function initialize(address _admin, IToken2048 _token2048) public initializer {
        admin = _admin;
        token2048 = _token2048;
    }

    function getBoard(uint256 id) public view returns (Board memory) {
        return boards[id];
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
        address indexed controller,
        uint256 indexed boardId,
        uint256 startIndex,
        uint256 nonce
    );

    function createBoard(
        address boardOwner,
        address controller,
        address paymentToken,
        uint256 nonce
    ) public payable returns (uint256 boardId, uint256 startIndex) {
        require(createBoardPrice[paymentToken] > 0, "Payment token not supported");
        require(paymentToken != address(0) || msg.value >= createBoardPrice[address(0)], "Underpay");

        uint256[] memory tiles = new uint256[](16);

        _resetBoard(tiles);

        startIndex = random(nonce) % 16;

        tiles[startIndex] = 2;

        boardId = boards.length;

        boards.push(
            Board({
                owner: boardOwner,
                controller: controller,
                id: boardId,
                score: 0,
                maxTile: 2,
                moves: 0,
                // active: true,
                tiles: tiles
            })
        );

        _mint(boardOwner, boardId);

        if (paymentToken != address(0)) {
            IERC20(paymentToken).transferFrom(msg.sender, address(this), createBoardPrice[paymentToken]);
        }

        uint256 controllerGas = msg.value;

        if (paymentToken == address(0)) {
            controllerGas -= createBoardPrice[address(0)];
        }

        if (controllerGas > 0) {
            (bool sendGasSuccess, ) = controller.call{value: controllerGas}("");
            require(sendGasSuccess, "Failed to send gas to controller");
        }

        emit CreateBoard(boardOwner, controller, boardId, startIndex, nonce);
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
                        if (stackPop * 2 > board.maxTile) {
                            board.maxTile = stackPop * 2;
                        }
                        stackPop = 0;
                    }
                }

                stackPop = 0;
            }

            require(
                keccak256(abi.encodePacked(tiles)) != tilesHash,
                "Cannot move in this direction"
            );
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
                        if (stackPop * 2 > board.maxTile) {
                            board.maxTile = stackPop * 2;
                        }
                        stackPop = 0;
                    }
                }

                stackPop = 0;
            }

            require(
                keccak256(abi.encodePacked(tiles)) != tilesHash,
                "Cannot move in this direction"
            );
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
                        if (stackPop * 2 > board.maxTile) {
                            board.maxTile = stackPop * 2;
                        }
                        stackPop = 0;
                    }
                }

                stackPop = 0;
            }

            require(
                keccak256(abi.encodePacked(tiles)) != tilesHash,
                "Cannot move in this direction"
            );
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
                        if (stackPop * 2 > board.maxTile) {
                            board.maxTile = stackPop * 2;
                        }
                        stackPop = 0;
                    }
                }

                stackPop = 0;
            }

            require(
                keccak256(abi.encodePacked(tiles)) != tilesHash,
                "Cannot move in this direction"
            );
        }
    }

    event HighScore(
        address indexed owner,
        uint256 indexed boardId,
        uint256 score
    );

    event Move(
        address indexed owner,
        uint256 indexed boardId,
        MoveDirection indexed dir,
        uint256 newIndex,
        uint256 extraScore,
        uint256 totalScore,
        uint256 maxTile,
        uint256 moves
    );

    function move(
        uint256 boardId,
        uint256 moveIndex,
        MoveDirection dir
    ) public onlyBoardController(boardId) {
        Board memory board = boards[boardId];
        uint256 extraScore;

        require(moveIndex == board.moves++, "Move already executed");

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

        if (board.score > highScores[board.owner]) {
            highScores[board.owner] = board.score;
            emit HighScore(board.owner, boardId, board.score);
        }

        if (address(token2048) != address(0)) {
            token2048.mint(board.owner, extraScore * 1e18);
        }

        (uint256 newIndex, ) = _new2(board);

        boards[boardId] = board;

        emit Move(board.owner, boardId, dir, newIndex, extraScore, board.score, board.maxTile, board.moves);
    }

    // event EndGame(
    //     address indexed owner,
    //     uint256 indexed boardId,
    //     uint256 totalScore
    // );

    // function endGame(uint256 boardId) public onlyBoardController(boardId) {
    //     uint256 score = boards[boardId].score;

    //     boards[boardId].active = false;

    //     if (address(token2048) != address(0)) {
    //         token2048.mint(boards[boardId].owner, score);
    //     }

    //     emit EndGame(boards[boardId].owner, boardId, score);
    // }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (address(metadataController) == address(0)) {
            return "";
        }

        return metadataController.tokenURI(tokenId);
    }

    function setMetadataController(IMetadata2048 controller) public onlyOwner {
        metadataController = controller;
    }

    event SetCreateBoardPrice(address indexed setter, address indexed token, uint256 price);
    function setCreateBoardPrice(address token, uint256 price) public onlyOwner {
        createBoardPrice[token] = price;
        emit SetCreateBoardPrice(msg.sender, token, price);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function transferOwnership(address newAdmin) public onlyOwner {
        emit OwnershipTransferred(admin, newAdmin);
        admin = newAdmin;
    }

    // Withdraw module
    function withdrawETH() public onlyOwner {
        address a = admin;
        (bool success, ) = a.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    function withdrawERC20(IERC20 token) public onlyOwner {
        token.transfer(admin, token.balanceOf(address(this)));
    }
}
