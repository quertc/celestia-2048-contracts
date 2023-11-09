//SPDX-License-Identifier: None
pragma solidity >=0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IToken2048.sol";

// Used for minting test ERC20s in our tests
contract Token2048 is ERC20("2048 Token", "2048"), Ownable, IToken2048 {
    mapping(address => bool) public minters;

    function setMinter(address minter, bool enabled) public onlyOwner {
        minters[minter] = enabled;
    }

    function mint(address to, uint256 amount) external {
        require(minters[msg.sender], "Forbidden");
        _mint(to, amount);
    }

    // Withdraw module
    function withdrawETH() public onlyOwner {
        address a = owner();
        (bool success, ) = a.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    function withdrawERC20(IERC20 token) public onlyOwner {
        token.transfer(owner(), token.balanceOf(address(this)));
    }
}
