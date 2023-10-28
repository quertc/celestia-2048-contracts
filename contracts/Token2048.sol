//SPDX-License-Identifier: None
pragma solidity >=0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IToken2048.sol";

// Used for minting test ERC20s in our tests
contract Token2048 is ERC20("2048 Token", "2048"), Ownable, IToken2048 {
    IMetadata2048 public metadataController;
    mapping(address => bool) public minters;

    function setMinter(address minter, bool enabled) public onlyOwner {
        minters[minter] = enabled;
    }

    function setMetadataController(IMetadata2048 controller) public onlyOwner {
        metadataController = controller;
    }

    function mint(address to, uint256 amount) external {
        require(minters[msg.sender], "Forbidden");
        _mint(to, amount);
    }
}
